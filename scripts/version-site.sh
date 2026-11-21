#!/usr/bin/env bash
# version-site.sh [--line-start] FILE PATTERN
#
# Exit 0 when FILE contains PATTERN (a fixed string) as a whole version: not
# followed by a character that would make it a different version (a letter,
# a digit, or one of . - + _ ~), and, when the pattern itself starts with a
# letter or digit, not preceded by one either ("dev1.0.27" does not hold
# "v1.0.27"). With --line-start the pattern must begin its line, so a
# "### v1.0.27" subheading does not stand in for the "## v1.0.27" heading.
#
# The gate used a plain fixed-string search, so "v1.0.27" also matched
# "v1.0.27-0.20261121005521-7d036c5cd957", a Go pseudo-version naming an
# untagged commit, and "1.0.27" would match "1.0.270". A release must not
# pass its gate pinned to an untagged commit. For a go.mod pin use
# gomod-pin.sh, which reads the require lines themselves.
set -uo pipefail

LINE_START=0
if [ "${1:-}" = "--line-start" ]; then LINE_START=1; shift; fi
FILE="${1:?usage: version-site.sh [--line-start] FILE PATTERN}"
PATTERN="${2:?usage: version-site.sh [--line-start] FILE PATTERN}"
[ -r "$FILE" ] || exit 1

P="$PATTERN" LS="$LINE_START" awk '
BEGIN { p = ENVIRON["P"]; n = length(p); ls = ENVIRON["LS"] + 0
        word = "[-+._~0-9A-Za-z]"; left = (substr(p, 1, 1) ~ /[0-9A-Za-z]/) }
{
    s = $0; off = 0
    while ((i = index(s, p)) > 0) {
        at = off + i                       # 1-based column of this occurrence
        before = (at > 1) ? substr($0, at - 1, 1) : ""
        after = substr($0, at + n, 1)
        good = (after !~ word)
        if (good && left && before ~ word) good = 0
        if (good && ls && at != 1) good = 0
        if (good) { found = 1; exit }
        s = substr(s, i + 1); off += i
    }
}
END { exit !found }
' "$FILE"
