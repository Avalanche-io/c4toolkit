#!/bin/bash
set -euo pipefail

# Coordinated release of the entire C4 suite.
#
# Usage: ./scripts/release.sh <suite-version> [--dry-run]
#
# Steps:
#   1. Validate all component versions exist (tags, packages)
#   2. Build Go binaries (calls build.sh)
#   3. Generate Homebrew formula (calls homebrew.sh)
#   4. Publish npm packages (@avalanche-io/c4, @avalanche-io/c4-node)
#   5. Publish PyPI package (c4py)
#   6. Create GitHub release with archives
#   7. Trigger container image builds
#
# Each step can also be run independently.

SUITE_VERSION="${1:?Usage: $0 <suite-version> [--dry-run]}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true

RELEASES="releases.json"

if [ ! -f "$RELEASES" ]; then
    echo "Error: $RELEASES not found" >&2
    exit 1
fi

if ! jq -e ".releases[\"${SUITE_VERSION}\"]" "$RELEASES" &>/dev/null; then
    echo "Error: suite version ${SUITE_VERSION} not found in $RELEASES" >&2
    exit 1
fi

echo "C4 Suite Release ${SUITE_VERSION}"
echo "================================"
if $DRY_RUN; then echo "(DRY RUN — no changes will be made)"; fi
echo ""

# Step 1: Validate all component tags exist
echo "=== Step 1: Validate component tags ==="
ALL_OK=true
COMPONENTS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components | to_entries[] | \"\(.key) \(.value.version) \(.value.repo) \(.value.lang)\"" "$RELEASES")

while IFS=' ' read -r name version repo lang; do
    case "$lang" in
        go|c)
            if git ls-remote --tags "https://github.com/${repo}.git" "v${version}" 2>/dev/null | grep -q "v${version}"; then
                echo "  OK  ${name} v${version}"
            else
                echo "  MISSING  ${name} v${version} — tag not found in ${repo}"
                ALL_OK=false
            fi
            ;;
        python)
            echo "  CHECK  ${name} v${version} — verify on PyPI manually"
            ;;
        typescript)
            echo "  CHECK  ${name} v${version} — verify on npm manually"
            ;;
        swift)
            if git ls-remote --tags "https://github.com/${repo}.git" "v${version}" 2>/dev/null | grep -q "v${version}"; then
                echo "  OK  ${name} v${version}"
            else
                echo "  MISSING  ${name} v${version} — tag not found in ${repo}"
                ALL_OK=false
            fi
            ;;
        docker)
            echo "  CHECK  ${name} v${version} — container images built by CI"
            ;;
    esac
done <<< "$COMPONENTS"

if ! $ALL_OK; then
    echo ""
    echo "Some components are missing tags. Fix before releasing." >&2
    exit 1
fi
echo ""

# Step 2: Build Go binaries
echo "=== Step 2: Build Go binaries ==="
if $DRY_RUN; then
    echo "  (skipped — dry run)"
else
    ./scripts/build.sh "$SUITE_VERSION"
fi
echo ""

# Step 3: Generate Homebrew formula
echo "=== Step 3: Generate Homebrew formula ==="
if $DRY_RUN; then
    echo "  (skipped — dry run)"
else
    ./scripts/homebrew.sh "$SUITE_VERSION"
fi
echo ""

# Step 4: Publish npm packages
echo "=== Step 4: npm packages ==="
TS_VERSION=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"c4ts\"].version" "$RELEASES")
if $DRY_RUN; then
    echo "  Would publish @avalanche-io/c4@${TS_VERSION}"
    echo "  Would publish @avalanche-io/c4-node@${TS_VERSION}"
else
    echo "  Publish npm packages manually:"
    echo "    cd <c4ts repo> && pnpm publish --filter @avalanche-io/c4"
    echo "    cd <c4ts repo> && pnpm publish --filter @avalanche-io/c4-node"
fi
echo ""

# Step 5: Publish PyPI package
echo "=== Step 5: PyPI package ==="
PY_VERSION=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"c4py\"].version" "$RELEASES")
if $DRY_RUN; then
    echo "  Would publish c4py==${PY_VERSION}"
else
    echo "  Publish PyPI package manually:"
    echo "    cd <c4py repo> && python -m build && twine upload dist/*"
fi
echo ""

# Step 6: Create GitHub release
echo "=== Step 6: GitHub release ==="
if $DRY_RUN; then
    echo "  Would create release v${SUITE_VERSION} on Avalanche-io/c4toolkit"
    echo "  Would upload $(ls dist/${SUITE_VERSION}/*.tar.gz dist/${SUITE_VERSION}/*.zip 2>/dev/null | wc -l | tr -d ' ') archives"
else
    NOTES=$(jq -r ".releases[\"${SUITE_VERSION}\"].notes" "$RELEASES")
    BODY="# C4 Suite ${SUITE_VERSION}

${NOTES}

## Component Versions

| Component | Version | Language |
|-----------|---------|----------|"

    while IFS=' ' read -r name version repo lang; do
        BODY="${BODY}
| ${name} | ${version} | ${lang} |"
    done <<< "$COMPONENTS"

    BODY="${BODY}

## Install

\`\`\`bash
# Homebrew (macOS/Linux)
brew install mrjoshuak/tap/c4

# Go tools
go install github.com/Avalanche-io/c4/cmd/c4@v$(jq -r ".releases[\"${SUITE_VERSION}\"].components.c4.version" "$RELEASES")
go install github.com/Avalanche-io/c4sh@v$(jq -r ".releases[\"${SUITE_VERSION}\"].components.c4sh.version" "$RELEASES")

# Python
pip install c4py

# TypeScript
npm install @avalanche-io/c4

# Swift
.package(url: \"https://github.com/Avalanche-io/c4-swift.git\", from: \"$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"c4-swift\"].version" "$RELEASES")\")
\`\`\`"

    echo "  Creating GitHub release..."
    gh release create "v${SUITE_VERSION}" \
        --repo Avalanche-io/c4toolkit \
        --title "C4 Suite ${SUITE_VERSION}" \
        --notes "$BODY" \
        dist/${SUITE_VERSION}/*.tar.gz \
        dist/${SUITE_VERSION}/*.zip \
        dist/${SUITE_VERSION}/checksums.txt
fi
echo ""

echo "=== Release ${SUITE_VERSION} complete ==="
