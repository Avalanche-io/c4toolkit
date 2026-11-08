class C4 < Formula
  desc "C4 universal content identification: the CLI tools (SMPTE ST 2114) and the farm tools"
  homepage "https://cccc.io"
  version "1.0.24"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.24/c4-suite_v1.0.24_darwin_arm64.tar.gz"
      sha256 "f6df3c3c2a65d9c45682b6f6104005eb3d899d6dbb21a703cf8fe39a9a7e3230"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.24/c4-suite_v1.0.24_darwin_amd64.tar.gz"
      sha256 "f11d4a0b87e0de845a53304f944ad1499ea352ea1b013fd642a6e3087e454c7e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.24/c4-suite_v1.0.24_linux_arm64.tar.gz"
      sha256 "2f12cece498a9331088bc42c3e88a9c4aebc825f0842366ec81f080d6d91c912"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.24/c4-suite_v1.0.24_linux_amd64.tar.gz"
      sha256 "a3363782a701dffb84b3f2cf79d9c3aaac3983515681fc145639df0df2a4599d"
    end
  end

  on_macos do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-farm_0.2.2_darwin_arm64.tar.gz"
        sha256 "138518ad31388179baa14cdb8a09e3717596b46555f00d9204556f1d70ca3bd1"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-agent_0.2.2_darwin_arm64.tar.gz"
        sha256 "1becad71bbf3033cfe609663dce9a8323a5f29db49b8aaa8e0a720b91b6dd720"
      end
    end
  end
  on_macos do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-farm_0.2.2_darwin_amd64.tar.gz"
        sha256 "7710921d4b62863589f43bbda21e23d3ce304dd5f2f99dabc583b8643da99ce1"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-agent_0.2.2_darwin_amd64.tar.gz"
        sha256 "0e9637253c2af60166d8c3846246556a4939a375ddf9fe041e568daf319178ae"
      end
    end
  end
  on_linux do
    if Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-farm_0.2.2_linux_arm64.tar.gz"
        sha256 "7786747816ab9c1b5516ffb2aa710ed5e86a5555f8f0fda8f7d90fa5489f08fd"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-agent_0.2.2_linux_arm64.tar.gz"
        sha256 "ed64ad34d1b59b90bc930933f917aa9e80e255d9d8658071b52e83bd7e40f191"
      end
    end
  end
  on_linux do
    if !Hardware::CPU.arm?
      resource "c4-farm" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-farm_0.2.2_linux_amd64.tar.gz"
        sha256 "49d8fe945b7da87dcde5d914a410d583c7b004889a540ff483e7da7bf8060c15"
      end
      resource "c4-agent" do
        url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.2.2/c4-agent_0.2.2_linux_amd64.tar.gz"
        sha256 "044e694e6abddc7e0c8a102a64de1e9cc4cc25062cacd541d5b3f9a9e190405e"
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
