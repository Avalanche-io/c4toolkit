#!/usr/bin/env bash
# Tests for version-site.sh: run it with no arguments; it exits 1 on the
# first case that goes the wrong way.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F=$(mktemp)
trap 'rm -f "$F"' EXIT
FAILED=0

# expect WANT(0|1) NAME PATTERN CONTENT
expect() {
    printf '%s\n' "$4" > "$F"
    "$HERE/version-site.sh" "$F" "$3"; got=$?
    if [ "$got" -eq "$1" ]; then echo "  ok: $2"; else echo "  FAIL: $2 (exit $got, want $1)"; FAILED=1; fi
}

PIN='github.com/Avalanche-io/c4 v1.0.27'
expect 0 "a tagged pin"                       "$PIN" '	github.com/Avalanche-io/c4 v1.0.27'
expect 0 "a tagged pin with a comment after"  "$PIN" '	github.com/Avalanche-io/c4 v1.0.27 // indirect'
expect 1 "a pseudo-version of an untagged commit" "$PIN" '	github.com/Avalanche-io/c4 v1.0.27-0.20261121005521-7d036c5cd957'
expect 1 "a pre-release"                      "$PIN" '	github.com/Avalanche-io/c4 v1.0.27-rc1'
expect 1 "build metadata"                     "$PIN" '	github.com/Avalanche-io/c4 v1.0.27+incompatible'
expect 1 "a longer patch number"              "$PIN" '	github.com/Avalanche-io/c4 v1.0.270'
expect 1 "a fourth component"                 "$PIN" '	github.com/Avalanche-io/c4 v1.0.27.1'
expect 1 "another version"                    "$PIN" '	github.com/Avalanche-io/c4 v1.0.26'
expect 0 "the tagged pin on a later line"     "$PIN" '	github.com/Avalanche-io/c4 v1.0.27-0.2026
	github.com/Avalanche-io/c4 v1.0.27'
expect 0 "a quoted version constant"          'const version = "1.0.27"' 'const version = "1.0.27"'
expect 0 "a changelog heading with a date"    '## v1.0.27' '## v1.0.27 (2026-11-21)'
expect 1 "a changelog heading of 1.0.270"     '## v1.0.27' '## v1.0.270'
expect 0 "a Dockerfile ARG"                   'ARG C4_VERSION=v1.0.27' 'ARG C4_VERSION=v1.0.27'
expect 0 "a CMake version before a paren"     'VERSION 1.0.27' '    VERSION 1.0.27)'
expect 1 "a missing file's pattern"           "$PIN" 'module example'

[ "$FAILED" -eq 0 ] && echo "version-site: all cases pass" || { echo "version-site: FAILED"; exit 1; }
