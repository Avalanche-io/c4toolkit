class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.14"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.14/c4-suite_v1.0.14_darwin_arm64.tar.gz"
      sha256 "f95942f79d02805d813b19510def94c9c6414f39a520c45c0b1bde9ec5853bd8"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.14/c4-suite_v1.0.14_darwin_amd64.tar.gz"
      sha256 "1b839c1994a89f97506aa5d1bc65186065b8bf4c218f11f97b45579b0c80c40b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.14/c4-suite_v1.0.14_linux_arm64.tar.gz"
      sha256 "3045431d173fea8fcb1ee1c0c0338c9697c13ddfc9d37c21fd2ad91f6c27fbf0"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.14/c4-suite_v1.0.14_linux_amd64.tar.gz"
      sha256 "9cdabf39bffd0954ef85e0fc54ee65fd897e773e13b63472052fa3813e7c78be"
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
