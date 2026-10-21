class C4Agent < Formula
  desc "C4's host runner and unit runner, for agent work and tool units on a machine outside the cluster"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-agent_0.1.0_darwin_arm64.tar.gz"
      sha256 "babce42dfa8acb59dd09bc2758a52af8ac05c98ad09c431a55f13fb14cba4393"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-agent_0.1.0_darwin_amd64.tar.gz"
      sha256 "8cb543369af3fe4de2b439a6966c30d5a75c4851090dc94704e5816598e840ef"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-agent_0.1.0_linux_arm64.tar.gz"
      sha256 "8fad8d8645bed0cb7d090f41e617da9ac1bb42ee5dd4d47e02b78afb9c93a599"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-agent_0.1.0_linux_amd64.tar.gz"
      sha256 "44a53e850794045b569efd0fe7be832c5c98eaa51697402bd226b458246f6fe7"
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
