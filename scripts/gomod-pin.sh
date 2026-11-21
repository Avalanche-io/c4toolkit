#!/usr/bin/env bash
# gomod-pin.sh GOMOD MODULE VERSION
#
# Exit 0 when the go.mod file requires MODULE at exactly VERSION: at least
# one require line names the module, and every require line that names it
# gives that version and nothing more. Comments are ignored, so a pin kept
# in a "// was v1.0.27" note does not count, and a pseudo-version
# ("v1.0.27-0.2026…-7d036c5cd957") or any other suffix is another version.
# A replace directive is a separate check in gate.sh.
set -uo pipefail

FILE="${1:?usage: gomod-pin.sh GOMOD MODULE VERSION}"
MODULE="${2:?usage: gomod-pin.sh GOMOD MODULE VERSION}"
VERSION="${3:?usage: gomod-pin.sh GOMOD MODULE VERSION}"
[ -r "$FILE" ] || exit 1

M="$MODULE" V="$VERSION" awk '
BEGIN { m = ENVIRON["M"]; v = ENVIRON["V"] }
{
    line = $0
    c = index(line, "//"); if (c > 0) line = substr(line, 1, c - 1)
    n = split(line, f, /[ \t]+/)
    # fields, skipping a leading empty one and a leading "require"
    k = 1; if (f[k] == "") k++; if (f[k] == "require") k++
    if (f[k] != m) next
    seen++
    if (f[k + 1] != v) bad++
    # nothing may follow the version on the line (comments are already gone)
    for (j = k + 2; j <= n; j++) if (f[j] != "") bad++
}
END { exit !(seen > 0 && bad == 0) }
' "$FILE"
