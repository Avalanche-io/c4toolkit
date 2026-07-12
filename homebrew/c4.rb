class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.16"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.16/c4-suite_v1.0.16_darwin_arm64.tar.gz"
      sha256 "be3f5eea68f5ab266f28d7d7d5a383e6b43fb23e52ae50119c21e3ac973716df"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.16/c4-suite_v1.0.16_darwin_amd64.tar.gz"
      sha256 "69389bdd3eac57efd9868f72cb131b5ca5cc795cae77cc5f81b781fd70114ab9"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.16/c4-suite_v1.0.16_linux_arm64.tar.gz"
      sha256 "cc03ebb06514dd58d897f520f15342a679c56661340026ff45d7b00e50cf53ee"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.16/c4-suite_v1.0.16_linux_amd64.tar.gz"
      sha256 "5807d3de9641d2274e61849b29c922aaaa122d592785883d529fac0cd040ba54"
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
