#!/bin/bash
set -euo pipefail

# Generate Homebrew formula for the C4 suite.
#
# Usage: ./scripts/homebrew.sh <suite-version>
#
# Reads checksums from dist/<suite-version>/checksums.txt and generates
# homebrew/c4.rb with URLs and SHA256 hashes for the suite bundles, for
# mrjoshuak/homebrew-tap (Formula/c4.rb). One formula: the suite's own
# Go tools from the bundle, and c4-farm, c4-agent and c4-unit as
# resources from the c4-operator release the suite pins. Homebrew 6
# trusts only the formula named on the command line, not its in-tap
# dependencies, so the formula must not depends_on another tap formula.

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

BASE_URL="https://github.com/Avalanche-io/c4toolkit/releases/download/v${SUITE_VERSION}"

GO_TOOLS=$(jq -r ".releases[\"${SUITE_VERSION}\"].components | to_entries[] | select(.value.lang == \"go\") | .key" "$RELEASES" 2>/dev/null || echo "c4")

# The suite's own Go tools install from the bundle. Components that come
# from a c4-operator release become resources of this one formula, fetched
# from that release's archives with the SHA256s from its checksums.txt.
INSTALL_LINES=""
OP_VERSION=""
for tool in $GO_TOOLS; do
    repo=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${tool}\"].repo" "$RELEASES")
    if [ "$repo" = "Avalanche-io/c4-operator" ]; then
        OP_VERSION=$(jq -r ".releases[\"${SUITE_VERSION}\"].components[\"${tool}\"].version" "$RELEASES")
        continue
    fi
    INSTALL_LINES="${INSTALL_LINES}    bin.install \"${tool}\"
"
done

RESOURCE_BLOCKS=""
RESOURCE_INSTALL=""
FARM_TEST_LINES=""
if [ -n "$OP_VERSION" ]; then
    OP_URL="https://github.com/Avalanche-io/c4-operator/releases/download/v${OP_VERSION}"
    OP_SUMS=$(mktemp)
    if [ -n "${OPERATOR_CHECKSUMS:-}" ]; then
        cp "$OPERATOR_CHECKSUMS" "$OP_SUMS"
    else
        curl -fsSL -o "$OP_SUMS" "${OP_URL}/checksums.txt" || { echo "Error: cannot fetch ${OP_URL}/checksums.txt" >&2; exit 1; }
    fi
    opsha() { local s; s=$(grep " $1\$" "$OP_SUMS" | awk '{print $1}'); [ -n "$s" ] || { echo "Error: $1 not in c4-operator checksums.txt" >&2; exit 1; }; echo "$s"; }
    # c4-farm on every platform; the c4-agent archive carries c4-agent and c4-unit
    for os_ in darwin linux; do
        blk=macos; [ "$os_" = "linux" ] && blk=linux   # the DSL says on_macos, the archives say darwin
        for arch in arm64 amd64; do
            cond="Hardware::CPU.arm?"; [ "$arch" = "amd64" ] && cond="!Hardware::CPU.arm?"
            RESOURCE_BLOCKS="${RESOURCE_BLOCKS}  on_${blk} do
    if ${cond}
      resource \"c4-farm\" do
        url \"${OP_URL}/c4-farm_${OP_VERSION}_${os_}_${arch}.tar.gz\"
        sha256 \"$(opsha c4-farm_${OP_VERSION}_${os_}_${arch}.tar.gz)\"
      end
      resource \"c4-agent\" do
        url \"${OP_URL}/c4-agent_${OP_VERSION}_${os_}_${arch}.tar.gz\"
        sha256 \"$(opsha c4-agent_${OP_VERSION}_${os_}_${arch}.tar.gz)\"
      end
    end
  end
"
        done
    done
    rm -f "$OP_SUMS"
    RESOURCE_INSTALL='    resource("c4-farm").stage do
      bin.install "c4-farm"
      (share/"c4-farm/skills").install "skills/c4-farm" if File.directory?("skills/c4-farm")
    end
    resource("c4-agent").stage do
      bin.install "c4-agent", "c4-unit"
    end
'
    FARM_TEST_LINES='    assert_match "c4 farm", shell_output("#{bin}/c4 help")
    system bin/"c4-farm", "help"
    system bin/"c4-agent", "help"
    assert_match "usage: c4-unit run", shell_output("#{bin}/c4-unit 2>&1", 2)
'
fi

mkdir -p homebrew

{
cat <<RUBY
class C4 < Formula
  desc "C4 universal content identification: the CLI tools (SMPTE ST 2114) and the farm tools"
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

RUBY
printf '%s' "$RESOURCE_BLOCKS"
cat <<RUBY
  def install
${INSTALL_LINES}${RESOURCE_INSTALL}  end

  test do
    assert_match "c4 ", shell_output("#{bin}/c4 version")
${FARM_TEST_LINES}  end
end
RUBY
} > "$FORMULA"

echo "Generated $FORMULA"
