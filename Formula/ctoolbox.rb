class Ctoolbox < Formula
  desc "Collective Toolbox: A graph‑based workspace for linking documents and data"
  homepage "https://collectivetoolbox.com/"
  url "https://collectivetoolbox.com/releases/src/ctoolbox-src-0.1.14-ae297353cf593de801907aeea73dddac853637ba.tar.gz"
  sha256 "0placeholder_src_sha256"
  version "0.1.14"

  # We use env :userpaths to preserve the host's rustup and musl-tools paths in CI.
  env :userpaths

  depends_on "bison" => :build
  depends_on "expat" => :build
  depends_on "libffi" => :build
  depends_on "meson" => :build
  depends_on "musl" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "rust" => :build

  resource "dependencies" do
    url "https://collectivetoolbox.com/releases/src/ctoolbox-dependencies-0.1.14-ae297353cf593de801907aeea73dddac853637ba.tar.gz"
    sha256 "0placeholder_deps_sha256"
  end

  def install
    # Extract vendor.tar inside the vendor/ directory to restore git-archived path dependencies.
    system "tar", "-xf", "vendor/vendor.tar", "-C", "vendor"

    # Stage dependencies to vendor/ctb-vendored
    (buildpath/"vendor/ctb-vendored").mkpath
    resource("dependencies").stage(buildpath/"vendor/ctb-vendored")

    # Configure Cargo to run offline and use the vendored sources
    File.open(".cargo/config.toml", "a") do |f|
      f.write <<~EOS

        [source.crates-io]
        replace-with = "vendored-sources"

        [source.vendored-sources]
        directory = "vendor/ctb-vendored/vendor"
      EOS
    end

    system "rm", "./vendor/TypeScript-built.tar" # Remove the TypeScript-built tarball to avoid using it in the build

    # Run the build
    # Ideally this should be sandboxed without network access, but that
    # currently seems to require root on Linux.
    # system "./scripts/run-without-network", "./build", "--release", "--no-tests", "--no-docs", "linux-x64-gnu"
    system "./scripts/run-without-network", "./build", "--release", "--no-tests", "--no-docs", "linux-x64-gnu"

    # Install the binaries
    bin.install "built/linux-x64-gnu/ctoolbox"
    bin.install "built/linux-x64-gnu/ctoolbox.rsrc"
  end

  test do
    # Simple validation command to verify the installation
    assert_match "Collective Toolbox", shell_output("#{bin}/ctoolbox help")
  end
end
