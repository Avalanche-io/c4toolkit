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
# The denylist lives in session-names.sh, shared with gate.sh. Correction,
# 1.0.22: the first gate (0ee640a) allowlisted every "c4-<word>" token with
# an ERE "\b", which git grep reads as a literal "b", so it matched nothing
# real; with a real word boundary an allowlist is unworkable.
# shellcheck source=session-names.sh
. "$(cd "$(dirname "$0")" && pwd)/session-names.sh"
session_names_check() {
    # $1: a checkout at the tag; $2: its name for the report
    local hits
    hits=$(session_names_hits "$1")
    if [ -n "$hits" ]; then
        echo "  session names: agent session or handoff references in ${2} (public text names roles, never sessions):"
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

            # The tagged tree's binary must report its own version: c4's
            # is a constant in cmd/c4, and the v1.0.22 tag shipped it
            # saying 1.0.21 because the bump commit was missed (superseded
            # by 1.0.23 the same day). Tools with a "build" path and a
            # "version" verb are run once on the host.
            BUILD_PATH=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${name}\"].build // empty" "$RELEASES")
            if [ -n "$BUILD_PATH" ] && [ "$repo" != "Avalanche-io/c4-operator" ]; then
                reported=$(cd "$CLONEDIR" && go run "./${BUILD_PATH}" version 2>/dev/null | head -1) || reported=""
                case "$reported" in
                    *"${version}"*) echo "  version: OK (${reported})" ;;
                    *) echo "  version: MISMATCH, binary reports '${reported}', tag is v${version}"; ERRORS=$((ERRORS + 1)) ;;
                esac
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
    # The suite marker: ~/.claude/check-release-gate.py requires it before
    # `gh release create v<version>` may run.
    mkdir -p "$HOME/.c4-release-gates"
    date -u +%FT%TZ > "$HOME/.c4-release-gates/suite-v${SUITE_VERSION}"
    echo "ALL OK — ready to release (gate marker: ~/.c4-release-gates/suite-v${SUITE_VERSION})"
fi
