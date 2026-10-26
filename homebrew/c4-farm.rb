class C4Farm < Formula
  desc "Submit work to a C4 farm, watch it and take its output home; c4 farm up makes a farm on this machine"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.2.1"
  license "Apache-2.0"

  deprecate! date: "2026-10-26", because: "c4 installs c4-farm, c4-agent and c4-unit: brew install mrjoshuak/tap/c4"
  depends_on "mrjoshuak/tap/c4-agent"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_darwin_arm64.tar.gz"
      sha256 "1f6de619831473d29d421abe9e90d23067ce1abf55b520c8035c85a7303cf4f2"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_darwin_amd64.tar.gz"
      sha256 "79bf7e19a44947ce157c10201ab249e47d5aa5ce0fc5c5bddc673023220a6cc6"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_linux_arm64.tar.gz"
      sha256 "cdbc984fc15e5457470258df672a639565b8bee20f8bfda7ed8b375963be4471"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_linux_amd64.tar.gz"
      sha256 "f39cb321e81927d3a8923ddabc94419cf97094a994969537fb2048a6eb080eb3"
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
