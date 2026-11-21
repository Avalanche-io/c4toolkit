#!/usr/bin/env bash
# go-release-env.sh: source this, then run Go through go_release.
#
# One Go environment for the release gate (gate-build.sh) and the release
# build (build.sh), so the binary the gate checks and the binaries that ship
# are built the same way, and neither depends on the shell they run in.
#
#   - Dropped from the caller: GOFLAGS (-modfile, -overlay, -mod=vendor …),
#     GOWORK, GOTOOLCHAIN, and the settings that choose where modules come
#     from and whether they are checked (GOPROXY, GONOPROXY, GOSUMDB,
#     GONOSUMDB, GONOSUMCHECK, GOPRIVATE, GOINSECURE). GOENV=off drops the
#     same settings made with `go env -w`.
#   - Set: -mod=readonly (go.mod and go.sum are used as committed and never
#     rewritten; a vendor folder is ignored; a module missing from go.sum
#     fails the build), GOWORK=off, GOTOOLCHAIN=local (a go line newer than
#     the installed Go fails instead of fetching a toolchain).
#   - Kept from the caller: -p=N, which only limits how many builds run at
#     once.
go_release() {
    local par
    par=$(printf '%s\n' ${GOFLAGS:-} | grep -E '^-p=[0-9]+$' | head -1 || true)
    env -u GOFLAGS -u GOWORK -u GOTOOLCHAIN \
        -u GOPROXY -u GONOPROXY -u GOSUMDB -u GONOSUMDB -u GONOSUMCHECK -u GOPRIVATE -u GOINSECURE \
        GOENV=off GOFLAGS="-mod=readonly${par:+ $par}" GOWORK=off GOTOOLCHAIN=local \
        go "$@"
}
