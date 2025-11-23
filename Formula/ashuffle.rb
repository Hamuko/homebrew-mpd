class Ashuffle < Formula
  desc "Automatic library-wide shuffle for mpd"
  homepage "https://github.com/joshkunz/ashuffle"
  url "https://github.com/joshkunz/ashuffle.git",
    using:    :git,
    tag:      "v3.14.10",
    revision: "56f20e3a91f7d8046887b4baef4750aa45d18ffc"
  license "MIT"
  head "https://github.com/joshkunz/ashuffle.git", branch: "master"

  bottle do
    root_url "https://github.com/Hamuko/homebrew-mpd/releases/download/ashuffle-3.14.10"
    sha256 cellar: :any, arm64_tahoe:   "02384f4fc8eb74b7c9cfac06e022db921bdc9377945b57d0def87df9f00bdb1f"
    sha256 cellar: :any, arm64_sequoia: "7b4fe987f8e073cb90712005d787b20b6b1d093b22b13da60a74bd67b55ea752"
    sha256 cellar: :any, arm64_sonoma:  "e1ab21445c7efd323176126e0d7b29c63a9f7f185a2c2f50bee6a391e88fbd1b"
    sha256               x86_64_linux:  "534418b5422bb4810802d05680f035a8da33cd2bddec0690766419e8c1b12b0b"
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libmpdclient"

  # The absl subproject refuses to build on macOS because
  # it doesn't link against CoreFoundation.
  # https://github.com/mesonbuild/abseil-cpp/pull/5
  patch :DATA

  def install
    ENV.deparallelize
    system "meson", *std_meson_args, "build"
    system "ninja", "-C", "build", "install", "-v"
  end

  test do
    # Create a mock MPD server that will list exactly one "file".
    port = free_port
    server = TCPServer.new("127.0.0.1", port)
    fork do
      loop do
        socket = server.accept
        socket.puts "OK MPD 0.23.5\n"
        10.times do
          request = socket.gets
          case request
          when "add \"dir/file.mp3\"\n"
            socket.puts "OK"
            break
          when "listall\n"
            socket.puts "directory: dir\nfile: dir/file.mp3\nOK\n"
          else
            socket.puts "OK\n"
          end
        end
        socket.close
      end
    end

    assert_match "Picking random songs out of a pool of 1.\nAdded 1 song.",
      shell_output("#{bin}/ashuffle --port #{port} --only 1")
  end
end
__END__
diff --git a/meson.build b/meson.build
index 26513a8..7b2dc46 100644
--- a/meson.build
+++ b/meson.build
@@ -117,6 +117,9 @@ if not get_option('unsupported_use_system_absl')
   foreach lib : absl_libs
     absl_deps += absl.dependency(lib)
   endforeach
+  if host_machine.system() == 'darwin'
+    absl_deps += dependency('CoreFoundation', required : false)
+  endif
 else
   cpp = meson.get_compiler('cpp')
