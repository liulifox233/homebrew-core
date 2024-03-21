class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.23.tar.gz"
  sha256 "7a491529c2aef1b2243ffc221f716303b1ec5d55896c055fd7b35a44e6973661"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "493803be8b86dd85bc80c93e6ea828a15677b98aaa603edb777f120b592cbda5"
    sha256 cellar: :any,                 arm64_ventura:  "deeed7783d4b034ad720dfb13af694f4d8417a58b4e6cb3e909bd7cba76544e5"
    sha256 cellar: :any,                 arm64_monterey: "70e8ab81cf199e15c98829e1819a752beca48b41627099fca437afa2eb6cf63e"
    sha256 cellar: :any,                 sonoma:         "093fc12af195ec87435f0255bd7d2e119352b2df75996eec334612a9ed5997b2"
    sha256 cellar: :any,                 ventura:        "0e79b244f1e36de37c4502dd1dba02ca6387c57baaa06a58bc63a818658fcbd5"
    sha256 cellar: :any,                 monterey:       "32d650233c1e486f665130d0020efc2ae06cc3b63ea3cf54349c6bfc69ff00aa"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "2d9d15523a5f71007598728354f15d3b94d3dd5b2414ae5ad1376a061a35ac80"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
