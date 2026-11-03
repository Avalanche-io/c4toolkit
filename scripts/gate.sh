#!/bin/bash
# gate.sh: the publication gate for one component, run BEFORE its tag exists.
#
#   ./scripts/gate.sh <component> <version> <checkout>
#
# Checks the exact commit about to be tagged, and only passes when all of:
#   - the checkout is clean and its HEAD is on origin (pushed);
#   - CI for that commit completed green (skipped where the repo's workflow
#     does not run on that branch, which is only c4-containers today);
#   - every version site in the tree says <version> (the per-component list
#     below is the whole reason this script exists: on 2026-11-03 c4 v1.0.22
#     was tagged with cmd/c4/main.go still saying 1.0.21, after the tag had
#     been published and pinned by c4sh and c4git; it was superseded by
#     1.0.23 the same day);
#   - a Go tool's binary, built from the tree, reports <version>;
#   - go.mod carries no replace directive;
#   - no agent session names or handoff references in tracked text;
#   - the tag does not already exist on origin.
# On success it writes ~/.c4-release-gates/<component>-v<version>-<sha>, which
# the Claude Code hook ~/.claude/check-release-gate.py requires before it lets
# `git tag`, a tag push, or any publish command run for that version.
set -euo pipefail

COMPONENT="${1:?Usage: $0 <component> <version> <checkout>}"
VERSION="${2:?Usage: $0 <component> <version> <checkout>}"
DIR="${3:?Usage: $0 <component> <version> <checkout>}"
VERSION="${VERSION#v}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=session-names.sh
. "$HERE/session-names.sh"

ERRORS=0
fail() { echo "  FAIL: $*"; ERRORS=$((ERRORS + 1)); }
ok() { echo "  ok: $*"; }

# site FILE PATTERN: the file must contain the pattern (fixed string).
site() {
    if grep -q -F -- "$2" "$DIR/$1" 2>/dev/null; then ok "$1 says $2"; else fail "$1 does not say '$2'"; fi
}

echo "Gate: ${COMPONENT} v${VERSION} at ${DIR}"

# 1. Clean and pushed.
if [ -n "$(git -C "$DIR" status --porcelain --untracked-files=no)" ]; then fail "working tree has uncommitted changes"; else ok "working tree clean"; fi
SHA=$(git -C "$DIR" rev-parse HEAD)
git -C "$DIR" fetch -q origin 2>/dev/null || true
ON_ORIGIN=$(git -C "$DIR" branch -r --contains "$SHA" 2>/dev/null | grep -v HEAD | sed 's/^ *//' | tr '\n' ' ')
if [ -z "$ON_ORIGIN" ]; then fail "HEAD ${SHA:0:7} is not on any origin branch (push first)"; else ok "HEAD ${SHA:0:7} is on origin: ${ON_ORIGIN}"; fi
REPO=$(git -C "$DIR" remote get-url origin | sed -E 's#\.git$##; s#^.*github\.com[:/]##')

# 2. CI green for this commit.
NEEDS_CI=true
case "$COMPONENT" in c4-containers) NEEDS_CI=false ;; esac
if $NEEDS_CI; then
    RUN=$(gh run list -R "$REPO" --commit "$SHA" --limit 5 --json status,conclusion,name -q '[.[] | select(.status=="completed")] | map(.conclusion) | unique | join(",")' 2>/dev/null || echo "")
    PENDING=$(gh run list -R "$REPO" --commit "$SHA" --limit 5 --json status -q '[.[] | select(.status!="completed")] | length' 2>/dev/null || echo 0)
    if [ "$RUN" = "success" ] && [ "${PENDING:-0}" = "0" ]; then ok "CI green for ${SHA:0:7} on ${REPO}"
    elif [ -z "$RUN" ] && [ "${PENDING:-0}" = "0" ]; then fail "no CI run found for ${SHA:0:7} on ${REPO}"
    else fail "CI for ${SHA:0:7} is '${RUN:-none}' with ${PENDING:-0} run(s) still going"; fi
else
    ok "CI: not run on this branch for ${COMPONENT}; the image build runs on the tag"
fi

# 3. Version sites, 4. binary, 5. no replace.
BUILD=""
case "$COMPONENT" in
    c4)
        site cmd/c4/main.go "const version = \"${VERSION}\""
        site CHANGELOG.md "## v${VERSION}"
        BUILD=./cmd/c4 ;;
    c4sh)
        site main.go "const version = \"${VERSION}\""
        site go.mod "github.com/Avalanche-io/c4 v${VERSION}"
        BUILD=. ;;
    c4git)
        site cmd/c4git/main.go "c4git ${VERSION}"
        site go.mod "github.com/Avalanche-io/c4 v${VERSION}"
        BUILD=./cmd/c4git ;;
    c4py)
        site pyproject.toml "version = \"${VERSION}\""
        site src/c4py/__init__.py "__version__ = \"${VERSION}\"" ;;
    c4ts)
        site packages/core/package.json "\"version\": \"${VERSION}\""
        site packages/node/package.json "\"version\": \"${VERSION}\""
        site packages/core/src/index.ts "v${VERSION}" ;;
    c4-swift)
        ok "no version site (SPM uses the tag)" ;;
    libc4)
        site CMakeLists.txt "VERSION ${VERSION}" ;;
    c4-containers)
        site .github/workflows/build.yml "C4_VERSION: \"v${VERSION}\""
        site c4/Dockerfile "ARG C4_VERSION=v${VERSION}"
        site c4-pipeline/Dockerfile "ARG C4_VERSION=v${VERSION}"
        site c4-s3worker/Dockerfile "ARG C4_VERSION=v${VERSION}" ;;
    *)
        fail "unknown component ${COMPONENT}: add its version sites to gate.sh" ;;
esac
if [ -n "$BUILD" ]; then
    reported=$(cd "$DIR" && go run "$BUILD" version 2>/dev/null | head -1) || reported=""
    case "$reported" in
        *"${VERSION}"*) ok "binary reports '${reported}'" ;;
        *) fail "binary reports '${reported}', not ${VERSION}" ;;
    esac
    if grep -q -E '^replace ' "$DIR/go.mod" 2>/dev/null; then fail "go.mod has a replace directive"; else ok "go.mod has no replace"; fi
fi

# 6. Session names.
hits=$(session_names_hits "$DIR")
if [ -n "$hits" ]; then fail "session or handoff names in tracked text:"; echo "$hits" | sed 's/^/      /'; else ok "no session names"; fi

# 7. Tag not already published.
if git ls-remote --tags origin "refs/tags/v${VERSION}" 2>/dev/null | grep -q .; then
    existing=$(git -C "$DIR" ls-remote origin "refs/tags/v${VERSION}" | cut -c1-7)
    if git -C "$DIR" rev-parse -q --verify "v${VERSION}^{commit}" >/dev/null 2>&1 && [ "$(git -C "$DIR" rev-parse "v${VERSION}^{commit}")" = "$SHA" ]; then
        ok "tag v${VERSION} already exists on origin at this commit"
    else
        fail "tag v${VERSION} already exists on origin (${existing}); a published tag is never moved"
    fi
else
    ok "tag v${VERSION} is free"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "GATE FAILED: ${ERRORS} problem(s); nothing may be tagged or published for ${COMPONENT} v${VERSION}"
    exit 1
fi
mkdir -p "$HOME/.c4-release-gates"
MARK="$HOME/.c4-release-gates/${COMPONENT}-v${VERSION}-${SHA}"
date -u +%FT%TZ > "$MARK"
echo "GATE OK: ${COMPONENT} v${VERSION} at ${SHA:0:7} (${MARK})"
