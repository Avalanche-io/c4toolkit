class C4 < Formula
  desc "C4 universal content identification: the CLI tools (SMPTE ST 2114) and the farm tools"
  homepage "https://cccc.io"
  version "1.0.20"
  revision 1
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

  on_macos do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_darwin_arm64.tar.gz"
        sha256 "1f6de619831473d29d421abe9e90d23067ce1abf55b520c8035c85a7303cf4f2"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_darwin_arm64.tar.gz"
        sha256 "21fbd4838dfe50c38b534f04bb6e9be47e07bb43ef059a594017ec91872d0f1b"
      end
    end
  end
  on_macos do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_darwin_amd64.tar.gz"
        sha256 "79bf7e19a44947ce157c10201ab249e47d5aa5ce0fc5c5bddc673023220a6cc6"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_darwin_amd64.tar.gz"
        sha256 "79d2e6c7ec79fb9adc3824dd2915fa0c5f4ddcf5a81a1beac5790861d7ad9e30"
      end
    end
  end
  on_linux do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_linux_arm64.tar.gz"
        sha256 "cdbc984fc15e5457470258df672a639565b8bee20f8bfda7ed8b375963be4471"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_linux_arm64.tar.gz"
        sha256 "58fef2f19248727ad343440a15623f4c97a37bb595ad3a6e599c31b3951dbd13"
      end
    end
  end
  on_linux do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-farm_0.2.1_linux_amd64.tar.gz"
        sha256 "f39cb321e81927d3a8923ddabc94419cf97094a994969537fb2048a6eb080eb3"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.1/c4-agent_0.2.1_linux_amd64.tar.gz"
        sha256 "95cf23dd5b460d296d4cf0bad24fed23b94b05c3c73169084d08bdeab5809658"
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
