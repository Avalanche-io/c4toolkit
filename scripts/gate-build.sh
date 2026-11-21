#!/usr/bin/env bash
# gate-build.sh CHECKOUT COMMIT PACKAGE
#
# Builds PACKAGE (for example ./cmd/c4) as COMMIT says it, and prints the
# first line of `<binary> version`. The principle: the gate builds what the
# commit says, in an environment it sets itself.
#
#   - The source is an export of COMMIT (git archive) into a fresh folder,
#     never the working tree, so nothing untracked or ignored there can
#     reach the build: a stray .go file, a vendor/ folder, a go.work.
#   - The Go environment is set, not inherited (go-release-env.sh, the one
#     build.sh uses too): the caller's GOFLAGS, GOWORK, GOTOOLCHAIN and
#     module-source settings are dropped; -mod=readonly, GOWORK=off and
#     GOTOOLCHAIN=local are set.
#   - `go mod verify` must pass first, so a dependency altered in the module
#     cache is not built from.
#
# Exit 0 with the version line on stdout; exit 1 with the reason on stderr.
set -uo pipefail

DIR="${1:?usage: gate-build.sh CHECKOUT COMMIT PACKAGE}"
SHA="${2:?usage: gate-build.sh CHECKOUT COMMIT PACKAGE}"
PKG="${3:?usage: gate-build.sh CHECKOUT COMMIT PACKAGE}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The Go environment, shared with build.sh so the two cannot drift.
. "$HERE/go-release-env.sh"

SRC=$(mktemp -d) || { echo "gate-build: no scratch folder" >&2; exit 1; }
cleanup() {
    # Only the folder mktemp made in this run, and only by its literal name.
    if [ -n "$SRC" ] && [ -d "$SRC" ] && [ "$SRC" != "/" ]; then chmod -R u+w "$SRC" 2>/dev/null; rm -r -- "$SRC"; fi
}
trap cleanup EXIT

if ! git -C "$DIR" archive "$SHA" | tar -x -C "$SRC"; then echo "gate-build: could not export ${SHA}" >&2; exit 1; fi
[ -f "$SRC/go.mod" ] || { echo "gate-build: ${SHA} has no go.mod" >&2; exit 1; }

if ! verify=$(cd "$SRC" && go_release mod verify 2>&1); then
    echo "gate-build: go mod verify failed: $(printf '%s' "$verify" | head -3 | tr '\n' ' ')" >&2; exit 1
fi
if ! out=$(cd "$SRC" && go_release run "$PKG" version 2>"$SRC/.gate-build.err"); then
    echo "gate-build: the build or the run failed: $(head -3 "$SRC/.gate-build.err" | tr '\n' ' ')" >&2; exit 1
fi
printf '%s\n' "$out" | head -1
