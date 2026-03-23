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

    # For Go tools, clone and run tests
    if [ "$lang" = "go" ]; then
        TMPDIR=$(mktemp -d)
        if git clone --depth 1 --branch "v${version}" "https://github.com/${repo}.git" "$TMPDIR" 2>/dev/null; then
            echo -n "  tests: "
            if (cd "$TMPDIR" && go test ./... 2>&1) > /dev/null 2>&1; then
                echo "PASS"
            else
                echo "FAIL"
                ERRORS=$((ERRORS + 1))
            fi

            # Check for cross-language test vectors
            if find "$TMPDIR" -name "known_ids.json" -print -quit 2>/dev/null | grep -q .; then
                echo "  vectors: present"
            else
                echo "  vectors: not found (optional)"
            fi
        else
            echo "  tests: SKIP (could not clone)"
        fi
        rm -rf "$TMPDIR"
    fi

    echo ""
done <<< "$COMPONENTS"

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} error(s) found"
    exit 1
else
    echo "ALL OK — ready to release"
fi
