class Ashuffle < Formula
  desc "Automatic library-wide shuffle for mpd"
  homepage "https://github.com/joshkunz/ashuffle"
  url "https://github.com/joshkunz/ashuffle.git",
    using:    :git,
    tag:      "v3.13.3",
    revision: "2034f9d03f253dd760f13e00143c2900237ede6b"
  license "MIT"
  head "https://github.com/joshkunz/ashuffle.git", branch: "master"

  bottle do
    root_url "https://github.com/Hamuko/homebrew-mpd/releases/download/ashuffle-3.13.3"
    sha256 cellar: :any, big_sur:      "615ad981bc15e1418d85624e1157338d0075f2e5f940c89a9b36f024074a16be"
    sha256               x86_64_linux: "fca41f7efac3bf595068e6d28b79311a049955e868c2f8729b50c2c30fbd8fbd"
  end

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
