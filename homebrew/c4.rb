class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.15"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.15/c4-suite_v1.0.15_darwin_arm64.tar.gz"
      sha256 "bb8375e4ca6e0252cba363b4c59f6d37bd45deb1d71fb7dfc8313e02d19fbdd3"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.15/c4-suite_v1.0.15_darwin_amd64.tar.gz"
      sha256 "3f092ded0db5fc8c152f376b8d745228fd2131dd75e7118b0c8af0accece20d8"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.15/c4-suite_v1.0.15_linux_arm64.tar.gz"
      sha256 "ed801a5451278ee01e07c0fbc3a83e71b41c77d597c7892dcbf3e1d9523dd1d6"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.15/c4-suite_v1.0.15_linux_amd64.tar.gz"
      sha256 "b7c639edc345a5b1431b9cd1893bc13afce34223aabba2d2c6fe7112ff75e518"
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
