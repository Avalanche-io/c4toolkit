class C4Agent < Formula
  desc "C4's host runner and unit runner, for agent work and tool units on a machine outside the cluster"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.2.0"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_darwin_arm64.tar.gz"
      sha256 "6a4295de685ad78f6fac529704b9f52310eec2cee5f871eee02082c9eee256ae"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_darwin_amd64.tar.gz"
      sha256 "768b4af103971bc2cc1af44de8e9ca285bf75f84477c8a8cb6a88c483d326ccc"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_linux_arm64.tar.gz"
      sha256 "262fd336380f1a82efe214eff10e05457b705c1cd0cf6b20b5b7fab606bca4d7"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_linux_amd64.tar.gz"
      sha256 "dfd9be9b595cecaf47bdadaf8cf86ee7118d27d88a9d1c3923114e1e07df8a1c"
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
