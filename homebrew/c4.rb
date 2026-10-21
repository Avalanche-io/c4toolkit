class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.19"
  license "Apache-2.0"


  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.19/c4-suite_v1.0.19_darwin_arm64.tar.gz"
      sha256 "4fcba69f571cfc25a15d3ea22729e30b7627b7f81b0ce72759a8e0b1d58a86ea"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.19/c4-suite_v1.0.19_darwin_amd64.tar.gz"
      sha256 "1815a74b5f7aec6672e27a07acaef09ddb518474528f2bf64dafd7fde90e0550"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.19/c4-suite_v1.0.19_linux_arm64.tar.gz"
      sha256 "a57a2d16e11097bd56d2a83020d994c598861d59525210e1e34add812b0197ab"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.19/c4-suite_v1.0.19_linux_amd64.tar.gz"
      sha256 "475b7001c8c2fd112176dea9e8903ac00ac92b528fa90c08d64229b8009a1f0d"
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
