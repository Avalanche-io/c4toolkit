#!/bin/bash
set -euo pipefail

# Build all Go tools in the C4 suite for all platforms.
#
# Usage: ./scripts/build.sh <suite-version>
#
# Reads component versions from releases.json, clones each Go tool
# at its tagged version, cross-compiles for all target platforms,
# and produces archives in dist/<suite-version>/.

SUITE_VERSION="${1:?Usage: $0 <suite-version>}"
DIST="dist/${SUITE_VERSION}"
RELEASES="releases.json"

if [ ! -f "$RELEASES" ]; then
    echo "Error: $RELEASES not found. Run from the c4toolkit directory." >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq" >&2
    exit 1
fi

if ! jq -e ".releases[\"${SUITE_VERSION}\"]" "$RELEASES" &>/dev/null; then
    echo "Error: suite version ${SUITE_VERSION} not found in $RELEASES" >&2
    jq -r '.releases | keys[]' "$RELEASES" >&2
    exit 1
fi

mkdir -p "$DIST"

PLATFORMS=(
    "darwin/amd64"
    "darwin/arm64"
    "linux/amd64"
    "linux/arm64"
    "windows/amd64"
    "windows/arm64"
)

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Build each Go component
GO_TOOLS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components | to_entries[] | select(.value.lang == \"go\") | .key" "$RELEASES")

for tool in $GO_TOOLS; do
    repo=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${tool}\"].repo" "$RELEASES")
    version=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${tool}\"].version" "$RELEASES")
    build_pkg=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${tool}\"].build" "$RELEASES")

    echo "=== ${tool} v${version} (${repo}) ==="

    git clone --depth 1 --branch "v${version}" "https://github.com/${repo}.git" "$WORKDIR/$tool" 2>/dev/null || {
        echo "  SKIP: tag v${version} not found" >&2
        continue
    }

    for platform in "${PLATFORMS[@]}"; do
        IFS='/' read -r os arch <<< "$platform"
        ext=""; [ "$os" = "windows" ] && ext=".exe"

        echo "  ${os}/${arch}"
        outdir="${DIST}/${tool}_v${version}_${os}_${arch}"
        mkdir -p "$outdir"

        GOOS=$os GOARCH=$arch CGO_ENABLED=0 \
            go build -C "$WORKDIR/$tool" \
            -trimpath -ldflags="-s -w" \
            -o "$(pwd)/${outdir}/${tool}${ext}" \
            "./${build_pkg}/" 2>/dev/null || {
            echo "    FAIL" >&2
            rm -rf "$outdir"
        }
    done
done

# Archive individual tools
echo "=== Archiving ==="
cd "$DIST"
for dir in */; do
    [ -d "$dir" ] || continue
    name="${dir%/}"
    if [[ "$name" == *"windows"* ]]; then
        zip -qr "${name}.zip" "$dir"
    else
        tar czf "${name}.tar.gz" "$dir"
    fi
    rm -rf "$dir"
done

# Suite bundles — all Go tools in one archive per platform
echo "=== Suite bundles ==="
for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r os arch <<< "$platform"
    bundle="c4-suite_v${SUITE_VERSION}_${os}_${arch}"
    mkdir -p "$bundle"

    for archive in *_${os}_${arch}.*; do
        [ -f "$archive" ] || continue
        if [[ "$archive" == *.zip ]]; then
            unzip -qo "$archive" -d _tmp/ 2>/dev/null
            find _tmp -type f -exec mv {} "$bundle/" \;
            rm -rf _tmp
        else
            tar xzf "$archive" -C "$bundle/" --strip-components=1 2>/dev/null
        fi
    done

    if [ "$(ls -A "$bundle" 2>/dev/null)" ]; then
        if [ "$os" = "windows" ]; then
            zip -qr "${bundle}.zip" "$bundle"
        else
            tar czf "${bundle}.tar.gz" "$bundle"
        fi
    fi
    rm -rf "$bundle"
done

shasum -a 256 *.tar.gz *.zip 2>/dev/null > checksums.txt

echo ""
echo "=== Suite ${SUITE_VERSION} ==="
ls -lh
