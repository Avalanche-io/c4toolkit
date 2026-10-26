class C4Farm < Formula
  desc "Submit work to a C4 farm, watch it and take its output home; c4 farm up makes a farm on this machine"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.2.0"
  license "Apache-2.0"

  deprecate! date: "2026-10-26", because: "c4 installs c4-farm, c4-agent and c4-unit: brew install mrjoshuak/tap/c4"
  depends_on "mrjoshuak/tap/c4-agent"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_darwin_arm64.tar.gz"
      sha256 "315deff1624bbf02ace6feadf2a67a85f4d605590ed92d7be7c4c40c94200ea8"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_darwin_amd64.tar.gz"
      sha256 "d7a29ea8299c968316252ffe18cbc94da9f46d7b1bfcf56e3ff35f100d2a3976"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_linux_arm64.tar.gz"
      sha256 "71411ba131c5e45741ec6bd37239e5389d89396ed2e6d34365c6981b193fa08a"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_linux_amd64.tar.gz"
      sha256 "857a9ba251c7ebcfe8d8f2194e97af921c4a39d61fc780d246b33e96f5eb2dbe"
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
