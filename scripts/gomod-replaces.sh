#!/usr/bin/env bash
# gomod-replaces.sh GOMOD
#
# Asks Go itself whether the go.mod file has any replace directive, so the
# answer does not depend on how the directive is written (at the line start,
# indented, or in a block). Prints each replaced module path.
#   exit 0: no replace directive
#   exit 1: at least one (printed, space-separated)
#   exit 2: go mod edit could not read the file (its message is printed)
set -uo pipefail

FILE="${1:?usage: gomod-replaces.sh GOMOD}"
json=$(GOFLAGS= GOWORK=off go mod edit -json "$FILE" 2>&1) || { printf '%s\n' "$json" | head -3; exit 2; }
# go mod edit -json prints a "Replace" array of {"Old": {"Path": …}, "New":
# {…}} objects when there is one, and no Replace field (or null, on older
# Go) when there is none. The "Module" field shows the output is the parse
# of a go.mod, so an empty or unexpected output is not read as "none".
printf '%s\n' "$json" | awk '
/^\t"Module": \{/     { parsed = 1 }
/^\t"Replace": \[/   { inrep = 1; next }
inrep && /^\t\]/     { inrep = 0 }
inrep && /"Old": \{/ { old = 1; next }
inrep && old && /"Path":/ { gsub(/^[ \t]*"Path": "|",?$/, ""); paths = paths (paths ? " " : "") $0; old = 0 }
END {
    if (paths != "") { print paths; exit 1 }
    if (parsed) exit 0
    print "go mod edit -json printed no Module field"; exit 2
}'
