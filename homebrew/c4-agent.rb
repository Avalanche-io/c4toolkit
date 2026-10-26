class C4Agent < Formula
  desc "C4's host runner and unit runner, for agent work and tool units on a machine outside the cluster"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.2.1"
  license "Apache-2.0"

  deprecate! date: "2026-10-26", because: "c4 installs c4-farm, c4-agent and c4-unit: brew install mrjoshuak/tap/c4"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_darwin_arm64.tar.gz"
      sha256 "21fbd4838dfe50c38b534f04bb6e9be47e07bb43ef059a594017ec91872d0f1b"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_darwin_amd64.tar.gz"
      sha256 "79d2e6c7ec79fb9adc3824dd2915fa0c5f4ddcf5a81a1beac5790861d7ad9e30"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_linux_arm64.tar.gz"
      sha256 "58fef2f19248727ad343440a15623f4c97a37bb595ad3a6e599c31b3951dbd13"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_linux_amd64.tar.gz"
      sha256 "95cf23dd5b460d296d4cf0bad24fed23b94b05c3c73169084d08bdeab5809658"
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
