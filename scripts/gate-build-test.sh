#!/usr/bin/env bash
# Tests for gate-build.sh, on a small module made in a scratch folder. Each
# attack is first shown to work on a plain `go run` in the working tree (the
# control), then shown not to reach gate-build.sh. Needs go and git; uses no
# network. Run with no arguments; exits 1 if any case goes the wrong way.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T=$(mktemp -d) || exit 1
cleanup() { if [ -n "$T" ] && [ -d "$T" ] && [ "$T" != "/" ]; then chmod -R u+w "$T" 2>/dev/null; rm -r -- "$T"; fi; }
trap cleanup EXIT
FAILED=0
ok() { echo "  ok: $*"; }
bad() { echo "  FAIL: $*"; FAILED=1; }
want() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }

export HOME="$T/home" GOFLAGS= GOWORK= GOTOOLCHAIN=local; unset GOFLAGS GOWORK
mkdir -p "$HOME" "$T/repo"
cd "$T/repo" || exit 1
git init -q . && git config user.email dev@studio.example && git config user.name "Example Dev"
printf 'module example.test/tool\n\ngo 1.21\n' > go.mod
printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("tool 1.2.3") }\n' > main.go
git add go.mod main.go && git commit -q -m "tool 1.2.3"
SHA=$(git rev-parse HEAD)
plain() { (cd "$T/repo" && go run . version 2>/dev/null | head -1); }
gate() { "$HERE/gate-build.sh" "$T/repo" "$SHA" . 2>/dev/null; }

echo "gate-build.sh:"
want "the commit as it is" "$(gate)" "tool 1.2.3"

# 1. An untracked source file in the working tree.
printf 'package main\n\nimport "fmt"\n\nfunc init() { fmt.Println("TAMPERED") }\n' > tamper.go
want "control: an untracked .go file changes a plain build" "$(plain)" "TAMPERED"
want "an untracked .go file does not reach the gate's build" "$(gate)" "tool 1.2.3"
rm -f tamper.go

# 2. The caller's GOFLAGS swapping a source file with -overlay.
printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("TAMPERED") }\n' > "$T/evil.go"
printf '{"Replace": {"%s": "%s"}}\n' "$T/repo/main.go" "$T/evil.go" > "$T/overlay.json"
want "control: GOFLAGS=-overlay changes a plain build" "$(GOFLAGS=-overlay=$T/overlay.json plain)" "TAMPERED"
want "the caller's GOFLAGS=-overlay does not reach the gate's build" "$(GOFLAGS=-overlay=$T/overlay.json gate)" "tool 1.2.3"

want "the caller's GOFLAGS=-p=2 is kept and the build works" "$(GOFLAGS=-p=2 gate)" "tool 1.2.3"
want "with -p=2 beside it, -overlay is still dropped" "$(GOFLAGS="-p=2 -overlay=$T/overlay.json" gate)" "tool 1.2.3"

# 3. The caller's GOFLAGS naming another go.mod.
printf 'module example.test/other\n\ngo 1.21\n' > "$T/alt.mod"
want "control: GOFLAGS=-modfile is honoured by a plain build" "$(cd "$T/repo" && GOFLAGS=-modfile=$T/alt.mod go list -m 2>/dev/null)" "example.test/other"
want "the caller's GOFLAGS=-modfile does not reach the gate's build" "$(GOFLAGS=-modfile=$T/alt.mod gate)" "tool 1.2.3"

# 4. A workspace: an untracked go.work, and one named by GOWORK.
printf 'go 1.21\n\nuse ./nowhere\n' > go.work
want "control: an untracked go.work breaks a plain build" "$(plain)" ""
want "an untracked go.work does not reach the gate's build" "$(gate)" "tool 1.2.3"
rm -f go.work
want "the caller's GOWORK does not reach the gate's build" "$(GOWORK=$T/none.work gate)" "tool 1.2.3"

# 5. A commit whose go.mod asks for a newer Go than is installed: the build
# fails; it does not fetch another toolchain.
printf 'module example.test/tool\n\ngo 1.999\n' > go.mod
git commit -q -am "asks for go 1.999"
NEWER=$(git rev-parse HEAD)
if out=$("$HERE/gate-build.sh" "$T/repo" "$NEWER" . 2>/dev/null); then bad "a go line newer than the installed Go builds anyway ('$out')"; else ok "a go line newer than the installed Go fails the build"; fi

[ "$FAILED" -eq 0 ] && echo "all cases pass" || { echo "FAILED"; exit 1; }
