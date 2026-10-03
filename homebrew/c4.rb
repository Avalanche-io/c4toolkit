class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.18"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.18/c4-suite_v1.0.18_darwin_arm64.tar.gz"
      sha256 "576911ff5c6ffd972e8c28af5b937dd376d5d0063961fdc7bb4394a4f08460b1"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.18/c4-suite_v1.0.18_darwin_amd64.tar.gz"
      sha256 "70f30d0e02afeb7261ff0ac67821244a870e97088e403c7681ec9dd07700df14"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.18/c4-suite_v1.0.18_linux_arm64.tar.gz"
      sha256 "859696f3a5db190bfeeee98a17152df7136fef15ec91ba158ad44598d113473a"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.18/c4-suite_v1.0.18_linux_amd64.tar.gz"
      sha256 "9509f7ed348e931bf500162b970243b37eba7ff8bddbbcf80c7b0bbfbc264585"
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
