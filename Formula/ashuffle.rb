class Ashuffle < Formula
  desc "Automatic library-wide shuffle for mpd"
  homepage "https://github.com/joshkunz/ashuffle"
  url "https://github.com/joshkunz/ashuffle.git",
    using:    :git,
    tag:      "v3.13.3",
    revision: "2034f9d03f253dd760f13e00143c2900237ede6b"
  license "MIT"
  head "https://github.com/joshkunz/ashuffle.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libmpdclient"

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
