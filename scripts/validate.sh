#!/bin/bash
set -euo pipefail

# Validate that all components are ready for a suite release.
#
# Usage: ./scripts/validate.sh <suite-version>
#
# Checks:
#   - All Go/Swift/C repos have the correct version tag
#   - Go tests pass for each component
#   - Cross-language test vectors are present
#   - Version strings in binaries match

SUITE_VERSION="${1:?Usage: $0 <suite-version>}"
RELEASES="releases.json"
ERRORS=0

if [ ! -f "$RELEASES" ]; then
    echo "Error: $RELEASES not found" >&2
    exit 1
fi

echo "Validating C4 Suite ${SUITE_VERSION}"
echo "===================================="
echo ""

COMPONENTS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components | to_entries[] | \"\(.key) \(.value.version) \(.value.repo) \(.value.lang)\"" "$RELEASES")

# Public repositories name roles, never agent sessions (Joshua, 2026-11-03).
# The gate lists no session names (that would publish them): every
# "c4-<word>" token in a tag's tracked text must be a known public name,
# and handoff paths and "-to-c4" relay names are refused outright.
PUBLIC_NAMES='c4-operator|c4-farm|c4-agent|c4-unit|c4-sync|c4-hud|c4-mark|c4-mcp|c4-containers|c4-swift|c4-python|c4-pipeline|c4-s3worker|c4-suite|c4-local|c4-local-registry|c4-system|c4-store|c4-manager|c4-node|c4-egress|c4-regional|c4-job-[a-z0-9]+|c4-sample[a-z0-9-]*|c4-[0-9]+|c4-cli|c4-id|c4-toolkit|c4-bench[a-z0-9-]*|c4-tab|c4-c4m|c4-lib|c4-go|c4-rs|c4-test[a-z0-9-]*|c4-found'
session_names_check() {
    # $1: a checkout at the tag; $2: its name for the report
    local hits
    hits=$(cd "$1" && {
        git grep -I -n -o -E '\bc4-[a-z][a-z0-9-]*' -- ':!node_modules' ':!*.lock' ':!*.sum' 2>/dev/null |
            grep -v -E ":(${PUBLIC_NAMES})$"
        git grep -I -n -E '\.handoff/|-to-c4[a-z-]*\b|\bc4-to-' -- ':!node_modules' 2>/dev/null
    } | head -8) || true # a clean tree makes grep exit 1; under set -e that killed the validator (1.0.22)
    if [ -n "$hits" ]; then
        echo "  session names: unknown c4-* names or handoff references in ${2} (public text names roles, never sessions; add a real product name to PUBLIC_NAMES):"
        echo "$hits" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
    else
        echo "  session names: none"
    fi
}

while IFS=' ' read -r name version repo lang; do
    echo "--- ${name} v${version} (${lang}) ---"

    # Check tag exists
    if [ "$lang" = "python" ] || [ "$lang" = "typescript" ] || [ "$lang" = "docker" ]; then
        echo "  tag: (checked via package registry)"
    elif git ls-remote --tags "https://github.com/${repo}.git" "refs/tags/v${version}" 2>/dev/null | grep -q "v${version}"; then
        echo "  tag: OK"
    else
        echo "  tag: MISSING v${version} in ${repo}"
        ERRORS=$((ERRORS + 1))
    fi

    # Every component's tagged tree is checked for agent session names.
    GATEDIR=$(mktemp -d)
    if git clone -q --depth 1 --branch "v${version}" "https://github.com/${repo}.git" "$GATEDIR" 2>/dev/null; then
        session_names_check "$GATEDIR" "${repo}@v${version}"
    else
        echo "  session names: (tag not cloneable yet; checked at build)"
    fi
    rm -rf "$GATEDIR"

    # Components taken from their own GitHub release ("asset") are checked
    # there: the archive must exist for darwin/arm64 (the rest at build time).
    ASSET_TPL=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${name}\"].asset // empty" "$RELEASES")
    if [ -n "$ASSET_TPL" ]; then
        asset=${ASSET_TPL//\{version\}/$version}; asset=${asset//\{os\}/darwin}; asset=${asset//\{arch\}/arm64}
        url="https://github.com/${repo}/releases/download/v${version}/${asset}.tar.gz"
        if curl -fsSLI -o /dev/null "$url"; then
            echo "  release asset: OK (${asset}.tar.gz)"
        else
            echo "  release asset: MISSING ${url}"
            ERRORS=$((ERRORS + 1))
        fi
        echo ""
        continue
    fi

    # For Go tools, clone and run tests
    if [ "$lang" = "go" ]; then
        CLONEDIR=$(mktemp -d)
        if git clone --depth 1 --branch "v${version}" "https://github.com/${repo}.git" "$CLONEDIR" 2>/dev/null; then
            # Optional "test": the packages to test (c4-operator's full suite needs a cluster)
            TEST_PKGS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${name}\"].test // \"./...\"" "$RELEASES")
            echo -n "  tests (${TEST_PKGS}): "
            if (cd "$CLONEDIR" && go test $TEST_PKGS 2>&1) > /dev/null 2>&1; then
                echo "PASS"
            else
                echo "FAIL"
                ERRORS=$((ERRORS + 1))
            fi

            # Check for cross-language test vectors
            if find "$CLONEDIR" -name "known_ids.json" -print -quit 2>/dev/null | grep -q .; then
                echo "  vectors: present"
            else
                echo "  vectors: not found (optional)"
            fi
        else
            echo "  tests: SKIP (could not clone)"
        fi
        rm -rf "$CLONEDIR"
    fi

    echo ""
done <<< "$COMPONENTS"

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} error(s) found"
    exit 1
else
    echo "ALL OK — ready to release"
fi
