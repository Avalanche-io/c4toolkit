#!/usr/bin/env bash
# version-site.sh FILE PATTERN
#
# Exit 0 when FILE contains PATTERN (a fixed string) as a whole version, that
# is, not followed by a character that would make it a different version: a
# letter, a digit, or one of "." "-" "+".
#
# The gate used a plain fixed-string search, so "v1.0.27" also matched
# "v1.0.27-0.20261121005521-7d036c5cd957", a Go pseudo-version naming an
# untagged commit, and "1.0.27" would match "1.0.270". A release must not
# pass its gate pinned to an untagged commit.
set -uo pipefail

FILE="${1:?usage: version-site.sh FILE PATTERN}"
PATTERN="${2:?usage: version-site.sh FILE PATTERN}"
[ -r "$FILE" ] || exit 1

P="$PATTERN" awk '
BEGIN { p = ENVIRON["P"]; n = length(p) }
{
    s = $0
    while ((i = index(s, p)) > 0) {
        c = substr(s, i + n, 1)
        if (c !~ /[-+.0-9A-Za-z]/) { found = 1; exit }
        s = substr(s, i + 1)
    }
}
END { exit !found }
' "$FILE"
