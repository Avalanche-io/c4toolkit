#!/bin/bash
set -euo pipefail

# Generate Homebrew formula for the C4 suite.
#
# Usage: ./scripts/homebrew.sh <suite-version>
#
# Reads checksums from dist/<suite-version>/checksums.txt and generates
# homebrew/c4.rb with URLs and SHA256 hashes for the suite bundles.

SUITE_VERSION="${1:?Usage: $0 <suite-version>}"
DIST="dist/${SUITE_VERSION}"
FORMULA="homebrew/c4.rb"
RELEASES="releases.json"

if [ ! -f "$DIST/checksums.txt" ]; then
    echo "Error: $DIST/checksums.txt not found. Run build.sh first." >&2
    exit 1
fi

DARWIN_AMD64_SHA=$(grep "c4-suite.*darwin_amd64" "$DIST/checksums.txt" | awk '{print $1}')
DARWIN_ARM64_SHA=$(grep "c4-suite.*darwin_arm64" "$DIST/checksums.txt" | awk '{print $1}')
LINUX_AMD64_SHA=$(grep "c4-suite.*linux_amd64" "$DIST/checksums.txt" | awk '{print $1}')
LINUX_ARM64_SHA=$(grep "c4-suite.*linux_arm64" "$DIST/checksums.txt" | awk '{print $1}')

BASE_URL="https://github.com/Avalanche-io/c4-releases/releases/download/v${SUITE_VERSION}"

GO_TOOLS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components | to_entries[] | select(.value.lang == \"go\") | .key" "$RELEASES" 2>/dev/null || echo "c4")

INSTALL_LINES=""
for tool in $GO_TOOLS; do
    INSTALL_LINES="${INSTALL_LINES}    bin.install \"${tool}\"
"
done

mkdir -p homebrew

cat > "$FORMULA" <<RUBY
class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "${SUITE_VERSION}"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-suite_v${SUITE_VERSION}_darwin_arm64.tar.gz"
      sha256 "${DARWIN_ARM64_SHA}"
    else
      url "${BASE_URL}/c4-suite_v${SUITE_VERSION}_darwin_amd64.tar.gz"
      sha256 "${DARWIN_AMD64_SHA}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-suite_v${SUITE_VERSION}_linux_arm64.tar.gz"
      sha256 "${LINUX_ARM64_SHA}"
    else
      url "${BASE_URL}/c4-suite_v${SUITE_VERSION}_linux_amd64.tar.gz"
      sha256 "${LINUX_AMD64_SHA}"
    end
  end

  def install
${INSTALL_LINES}  end

  test do
    assert_match "c4 ", shell_output("#{bin}/c4 version")
  end
end
RUBY

echo "Generated $FORMULA"
