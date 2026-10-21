#!/bin/bash
set -euo pipefail

# Generate the Homebrew formulas for the farm tools from a c4-operator
# release, for Avalanche-io/homebrew-tap: homebrew/c4-farm.rb and
# homebrew/c4-agent.rb. The formulas point at the release's own archives
# (goreleaser's c4-farm_<v>_<os>_<arch>.tar.gz and c4-agent_...), with
# the SHA256s from its checksums.txt.
#
# Usage: ./scripts/farm-formulas.sh <c4-operator-version>   (e.g. 0.1.0)
#
# c4-operator's goreleaser can push these itself (its `brews` section)
# when HOMEBREW_TAP_TOKEN is set on that repository. This script is the
# laptop path, the same as scripts/homebrew.sh for c4.rb: no token, the
# formulas are generated from the published release and pushed by hand.

VERSION="${1:?Usage: $0 <c4-operator-version>}"
REPO="Avalanche-io/c4-operator"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

SUMS=$(mktemp)
trap 'rm -f "$SUMS"' EXIT
curl -fsSL -o "$SUMS" "${BASE_URL}/checksums.txt"

sha() { grep " $1\$" "$SUMS" | awk '{print $1}'; }
need() { local s; s=$(sha "$1"); [ -n "$s" ] || { echo "Error: $1 not in checksums.txt" >&2; exit 1; }; echo "$s"; }

mkdir -p homebrew

cat > homebrew/c4-farm.rb <<RUBY
class C4Farm < Formula
  desc "Submit work to a C4 farm, watch it and take its output home; c4 farm up makes a farm on this machine"
  homepage "https://github.com/${REPO}"
  version "${VERSION}"
  license "Apache-2.0"

  depends_on "avalanche-io/tap/c4-agent"

  on_macos do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-farm_${VERSION}_darwin_arm64.tar.gz"
      sha256 "$(need c4-farm_${VERSION}_darwin_arm64.tar.gz)"
    else
      url "${BASE_URL}/c4-farm_${VERSION}_darwin_amd64.tar.gz"
      sha256 "$(need c4-farm_${VERSION}_darwin_amd64.tar.gz)"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-farm_${VERSION}_linux_arm64.tar.gz"
      sha256 "$(need c4-farm_${VERSION}_linux_arm64.tar.gz)"
    else
      url "${BASE_URL}/c4-farm_${VERSION}_linux_amd64.tar.gz"
      sha256 "$(need c4-farm_${VERSION}_linux_amd64.tar.gz)"
    end
  end

  def install
    bin.install "c4-farm"
    (share/"c4-farm/skills").install "skills/c4-farm"
  end

  test do
    system bin/"c4-farm", "help"
  end
end
RUBY

cat > homebrew/c4-agent.rb <<RUBY
class C4Agent < Formula
  desc "C4's host runner and unit runner, for agent work and tool units on a machine outside the cluster"
  homepage "https://github.com/${REPO}"
  version "${VERSION}"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-agent_${VERSION}_darwin_arm64.tar.gz"
      sha256 "$(need c4-agent_${VERSION}_darwin_arm64.tar.gz)"
    else
      url "${BASE_URL}/c4-agent_${VERSION}_darwin_amd64.tar.gz"
      sha256 "$(need c4-agent_${VERSION}_darwin_amd64.tar.gz)"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "${BASE_URL}/c4-agent_${VERSION}_linux_arm64.tar.gz"
      sha256 "$(need c4-agent_${VERSION}_linux_arm64.tar.gz)"
    else
      url "${BASE_URL}/c4-agent_${VERSION}_linux_amd64.tar.gz"
      sha256 "$(need c4-agent_${VERSION}_linux_amd64.tar.gz)"
    end
  end

  def install
    bin.install "c4-agent", "c4-unit"
  end

  test do
    system bin/"c4-agent", "help"
    assert_match "usage: c4-unit run", shell_output("#{bin}/c4-unit 2>&1", 2)
  end
end
RUBY

echo "Generated homebrew/c4-farm.rb and homebrew/c4-agent.rb for c4-operator v${VERSION}"
