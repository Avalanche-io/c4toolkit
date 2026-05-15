class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.13"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.13/c4-suite_v1.0.13_darwin_arm64.tar.gz"
      sha256 "71d65a6d7849ee3404de6ff70e6b58b53370178b3e7bc8398c6ec4c84f7d17d4"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.13/c4-suite_v1.0.13_darwin_amd64.tar.gz"
      sha256 "92ee83675ca3cd35c850ed1dd506da2e1850f19c75ff8bec886bbb3419ee7f2c"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.13/c4-suite_v1.0.13_linux_arm64.tar.gz"
      sha256 "44fd964012985c2b828f384baf58086dfedcc805a9b15ccbf14c6b1d82e1c0e9"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.13/c4-suite_v1.0.13_linux_amd64.tar.gz"
      sha256 "23399b450afbc62bd6348affef1a04a673e460a0e3b470a1a7f6cbe3db5ddfce"
    end
  end

  def install
    bin.install "c4"
    bin.install "c4sh"
    bin.install "c4git"
  end

  test do
    assert_match "c4 ", shell_output("#{bin}/c4 version")
  end
end
