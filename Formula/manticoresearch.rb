class Manticoresearch < Formula
  desc "Open source text search engine"
  homepage "https://www.manticoresearch.com"
  url "https://github.com/manticoresoftware/manticoresearch/releases/download/3.2.0/manticore-3.2.0-191017-e526a01-release.tar.gz"
  version "3.2.0"
  sha256 "df6dbcc4df01065fc3cc6328f043b8cef3eb403a28671455cd3c8fc4217e3391"
  head "https://github.com/manticoresoftware/manticoresearch.git"

  bottle do
    root_url "http://dev.manticoresearch.com/bottles"
    sha256 "8d0599adafa21642a7a6c3bddc1df3c6552f479564042acb24fe53fcc92f9f37" => :mojave
  end

  depends_on "cmake" => :build
  depends_on "icu4c" => :build
  depends_on "libpq" => :build
  depends_on "mysql@5.7" => :build
  depends_on "unixodbc" => :build
  depends_on "openssl"

  conflicts_with "sphinx",
   :because => "manticore,sphinx install the same binaries."

  def install
    args = %W[
      -DCMAKE_INSTALL_LOCALSTATEDIR=#{var}
      -DDISTR_BUILD=macosbrew
    ]
    mkdir "build" do
      system "cmake", "..", *std_cmake_args, *args
      system "make", "install"
    end
  end

  def post_install
    (var/"run/manticore").mkpath
    (var/"log/manticore").mkpath
    (var/"data/manticore").mkpath
  end

  def caveats
    <<~EOS
      Config file is located at #{etc}/manticore/sphinx.conf
    EOS
  end

  plist_options :manual => "searchd --config #{HOMEBREW_PREFIX}/etc/manticore/sphinx.conf"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/searchd</string>
            <string>--config</string>
            <string>#{etc}/manticore/sphinx.conf</string>
            <string>--nodetach</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
  EOS
  end
  test do
    begin
      (testpath/"sphinx.conf").write <<~EOS
        searchd {
          pid_file = searchd.pid
          binlog_path=#
        }
      EOS
      system bin/"searchd"
      pid = fork do
        exec bin/"searchd"
      end
    ensure
      Process.kill(9, pid)
      Process.wait(pid)
    end
  end
end
