#!/usr/bin/env bash
# Tests for version-site.sh and gomod-pin.sh: run with no arguments; exits 1
# if any case goes the wrong way.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F=$(mktemp)
trap 'rm -f "$F"' EXIT
FAILED=0

report() { if [ "$1" -eq "$2" ]; then echo "  ok: $3"; else echo "  FAIL: $3 (exit $1, want $2)"; FAILED=1; fi; }

# site WANT(0|1) NAME PATTERN CONTENT [--line-start]
site() {
    printf '%s\n' "$4" > "$F"
    if [ "${5:-}" = "--line-start" ]; then "$HERE/version-site.sh" --line-start "$F" "$3"; else "$HERE/version-site.sh" "$F" "$3"; fi
    report $? "$1" "$2"
}

# pin WANT(0|1) NAME CONTENT   (module github.com/Avalanche-io/c4 at v1.0.27)
pin() {
    printf '%s\n' "$3" > "$F"
    "$HERE/gomod-pin.sh" "$F" github.com/Avalanche-io/c4 v1.0.27
    report $? "$1" "$2"
}

echo "version-site.sh:"
site 0 "a quoted version constant"           'const version = "1.0.27"' 'const version = "1.0.27"'
site 1 "a quoted constant of another version" 'const version = "1.0.27"' 'const version = "1.0.26"'
site 0 "a changelog heading with a date"     '## v1.0.27' '## v1.0.27 (2026-11-21)' --line-start
site 1 "a changelog heading of 1.0.270"      '## v1.0.27' '## v1.0.270' --line-start
site 1 "a subheading in place of the heading" '## v1.0.27' '### v1.0.27' --line-start
site 1 "the heading quoted mid-line"         '## v1.0.27' 'see ## v1.0.27 below' --line-start
site 0 "a Dockerfile ARG"                    'ARG C4_VERSION=v1.0.27' 'ARG C4_VERSION=v1.0.27'
site 0 "a CMake version before a paren"      'VERSION 1.0.27' '    VERSION 1.0.27)'
site 0 "a version in a comment line"         'v1.0.27' '// @avalanche-io/c4 v1.0.27'
site 1 "a version inside a longer word"      'v1.0.27' "const tag = 'dev1.0.27'"
site 1 "a pre-release with a hyphen"         'v1.0.27' '// @avalanche-io/c4 v1.0.27-rc1'
site 1 "a suffix with an underscore"         'v1.0.27' '// @avalanche-io/c4 v1.0.27_rc1'
site 1 "a suffix with a tilde"               'v1.0.27' '// @avalanche-io/c4 v1.0.27~beta'
site 1 "build metadata"                      'v1.0.27' '// @avalanche-io/c4 v1.0.27+1'
site 1 "a fourth component"                  'v1.0.27' '// @avalanche-io/c4 v1.0.27.1'
site 0 "a good occurrence after a bad one"   'v1.0.27' 'v1.0.27-rc1 then v1.0.27'

echo "gomod-pin.sh:"
pin 0 "a tagged pin"                          '	github.com/Avalanche-io/c4 v1.0.27'
pin 0 "a tagged pin on a require line"        'require github.com/Avalanche-io/c4 v1.0.27'
pin 0 "a tagged pin with a comment after"     '	github.com/Avalanche-io/c4 v1.0.27 // indirect'
pin 1 "a pseudo-version of an untagged commit" '	github.com/Avalanche-io/c4 v1.0.27-0.20261121005521-7d036c5cd957'
pin 1 "a pre-release"                         '	github.com/Avalanche-io/c4 v1.0.27-rc1'
pin 1 "build metadata"                        '	github.com/Avalanche-io/c4 v1.0.27+incompatible'
pin 1 "a longer patch number"                 '	github.com/Avalanche-io/c4 v1.0.270'
pin 1 "another version"                       '	github.com/Avalanche-io/c4 v1.0.26'
pin 1 "the tag only in a comment"             '	github.com/Avalanche-io/c4 v1.0.27-0.20261121005521-7d036c5cd957 // was github.com/Avalanche-io/c4 v1.0.27'
pin 1 "the tag on a comment line, a pseudo-version required" '// github.com/Avalanche-io/c4 v1.0.27
	github.com/Avalanche-io/c4 v1.0.27-0.20261121005521-7d036c5cd957'
pin 1 "two require lines that disagree"       '	github.com/Avalanche-io/c4 v1.0.27
	github.com/Avalanche-io/c4 v1.0.26'
pin 1 "the module in a replace block"         '	github.com/Avalanche-io/c4 v1.0.27
	github.com/Avalanche-io/c4 => ../c4'
pin 1 "no require line for the module"        'module github.com/Avalanche-io/c4sh'
pin 1 "another module with the same prefix"   '	github.com/Avalanche-io/c4sh v1.0.27'

[ "$FAILED" -eq 0 ] && echo "all cases pass" || { echo "FAILED"; exit 1; }
