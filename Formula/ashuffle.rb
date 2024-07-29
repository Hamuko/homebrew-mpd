class Ashuffle < Formula
  desc "Automatic library-wide shuffle for mpd"
  homepage "https://github.com/joshkunz/ashuffle"
  url "https://github.com/joshkunz/ashuffle.git",
    using:    :git,
    tag:      "v3.14.8",
    revision: "53e7bd799189261ca49efb8cac2039e9d7a9e644"
  license "MIT"
  head "https://github.com/joshkunz/ashuffle.git", branch: "master"

  bottle do
    root_url "https://github.com/Hamuko/homebrew-mpd/releases/download/ashuffle-3.14.1"
    sha256 cellar: :any,                 monterey:     "512d8c1e536df5d86e5376b1f7ee5a6cfcc6fca8a6f8f2f0c781ca07f2dcf14a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "3073035df1cddc516013e6a8157ce3a83c585d55a34bb398d6a43997a5261645"
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
