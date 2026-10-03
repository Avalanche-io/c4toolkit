class C4 < Formula
  desc "C4 Universal Content Identification — CLI tools (SMPTE ST 2114)"
  homepage "https://cccc.io"
  version "1.0.17"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.17/c4-suite_v1.0.17_darwin_arm64.tar.gz"
      sha256 "454b21cafa5b8c3de04fb990c9d79a30bedfd2f67b4473d7ea85bb1bf13ea1aa"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.17/c4-suite_v1.0.17_darwin_amd64.tar.gz"
      sha256 "19232b5c54b828226681e98b9b34628796d9ca436d749f015ebbf3d74ba6db5a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.17/c4-suite_v1.0.17_linux_arm64.tar.gz"
      sha256 "56c518251cc57f4d8b3abfff5caa8477dc365edd07d34d2ce2d5359eb206adf1"
    else
      url "https://github.com/Avalanche-io/c4toolkit/releases/download/v1.0.17/c4-suite_v1.0.17_linux_amd64.tar.gz"
      sha256 "52cdfaa9df9543587698434a11160043b83857d11584e61d725aa49b4b14f10f"
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
