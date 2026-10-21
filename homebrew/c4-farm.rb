class C4Farm < Formula
  desc "Submit work to a C4 farm, watch it and take its output home; c4 farm up makes a farm on this machine"
  homepage "https://github.com/Avalanche-io/c4-operator"
  version "0.1.0"
  license "Apache-2.0"

  depends_on "mrjoshuak/tap/c4-agent"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-farm_0.1.0_darwin_arm64.tar.gz"
      sha256 "a0f22f9e4c0e7b3d2e450de53e0e48814a27831cbfdd6c3e973b5e56f4366756"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-farm_0.1.0_darwin_amd64.tar.gz"
      sha256 "2862cf62a8eb1b73bebb078cf1240c3e3503590f6d2bd0f20844217f919cd7af"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-farm_0.1.0_linux_arm64.tar.gz"
      sha256 "9a29f672d295dc2574f41c6f9e5832820ca6a65356b8745a1e1859a991716bdd"
    else
      url "https://github.com/Avalanche-io/c4-operator/releases/download/v0.1.0/c4-farm_0.1.0_linux_amd64.tar.gz"
      sha256 "6d9c5479854d43369b60bbb3bbe46565c8872e963b5ee557c775000bfbedecd7"
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
