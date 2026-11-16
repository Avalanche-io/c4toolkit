class C4 < Formula
  desc "C4 universal content identification: the CLI tools (SMPTE ST 2114) and the farm tools"
  homepage "https://cccc.io"
  version "1.0.26"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.26/c4-suite_v1.0.26_darwin_arm64.tar.gz"
      sha256 "3aec02fcdef338ef5b4837cd4a91888455f88ce730558321a5e9a696105c76aa"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.26/c4-suite_v1.0.26_darwin_amd64.tar.gz"
      sha256 "7061e8b73de65c5fdfc6ee4e0fd7a69ca720e48dce74af722d166c9246c2313a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.26/c4-suite_v1.0.26_linux_arm64.tar.gz"
      sha256 "ce4526289abbf564a07090fb023181c7c784f261c129ca55bf4d686b21a1209e"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.26/c4-suite_v1.0.26_linux_amd64.tar.gz"
      sha256 "78fb65f73b11dd322e74fdccc4d1c5206eac4dff1b2e813166d51e004a863966"
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
