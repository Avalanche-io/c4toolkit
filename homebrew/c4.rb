class C4 < Formula
  desc "C4 universal content identification: the CLI tools (SMPTE ST 2114) and the farm tools"
  homepage "https://cccc.io"
  version "1.0.20"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.20/c4-suite_v1.0.20_darwin_arm64.tar.gz"
      sha256 "98a5dd756d5e91d8e617e69dc22bb9764e720dfc75cd7b81f7db327ea9855a67"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.20/c4-suite_v1.0.20_darwin_amd64.tar.gz"
      sha256 "21dc03a5b210ae4cf485bb8a1c8c9bcebfe4462d373c40b01bfbc752fc075129"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.20/c4-suite_v1.0.20_linux_arm64.tar.gz"
      sha256 "dd1e7dd8a03fa3d4d9686e849cefc8f9fe8364792bbef1cfadf329cce84ec077"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.20/c4-suite_v1.0.20_linux_amd64.tar.gz"
      sha256 "986aa3abefee01e144b71c4e3c5dcf2cfa6c79c5c33325fabd8ee9082e57b0fd"
    end
  end

  on_darwin do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_darwin_arm64.tar.gz"
        sha256 "315deff1624bbf02ace6feadf2a67a85f4d605590ed92d7be7c4c40c94200ea8"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_darwin_arm64.tar.gz"
        sha256 "6a4295de685ad78f6fac529704b9f52310eec2cee5f871eee02082c9eee256ae"
      end
    end
  end
  on_darwin do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_darwin_amd64.tar.gz"
        sha256 "d7a29ea8299c968316252ffe18cbc94da9f46d7b1bfcf56e3ff35f100d2a3976"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_darwin_amd64.tar.gz"
        sha256 "768b4af103971bc2cc1af44de8e9ca285bf75f84477c8a8cb6a88c483d326ccc"
      end
    end
  end
  on_linux do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_linux_arm64.tar.gz"
        sha256 "71411ba131c5e45741ec6bd37239e5389d89396ed2e6d34365c6981b193fa08a"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_linux_arm64.tar.gz"
        sha256 "262fd336380f1a82efe214eff10e05457b705c1cd0cf6b20b5b7fab606bca4d7"
      end
    end
  end
  on_linux do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-farm_0.2.0_linux_amd64.tar.gz"
        sha256 "857a9ba251c7ebcfe8d8f2194e97af921c4a39d61fc780d246b33e96f5eb2dbe"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.0/c4-agent_0.2.0_linux_amd64.tar.gz"
        sha256 "dfd9be9b595cecaf47bdadaf8cf86ee7118d27d88a9d1c3923114e1e07df8a1c"
      end
    end
  end
  def install
    bin.install "c4"
    bin.install "c4sh"
    bin.install "c4git"
    resource("c4-farm").stage do
      bin.install "c4-farm"
      (share/"c4-farm/skills").install "skills/c4-farm" if File.directory?("skills/c4-farm")
    end
    resource("c4-agent").stage do
      bin.install "c4-agent", "c4-unit"
    end
  end

  test do
    assert_match "c4 ", shell_output("#{bin}/c4 version")
    assert_match "c4 farm", shell_output("#{bin}/c4 help")
    system bin/"c4-farm", "help"
    system bin/"c4-agent", "help"
    assert_match "usage: c4-unit run", shell_output("#{bin}/c4-unit 2>&1", 2)
  end
end
