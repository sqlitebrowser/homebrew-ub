class Db4ssqlcipherub < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  url "https://github.com/sqlcipher/sqlcipher/archive/v4.5.5.tar.gz"
  sha256 "014ef9d4f5b5f4e7af4d93ad399667947bb55e31860e671f0def1b8ae6f05de0"
  head "https://github.com/sqlcipher/sqlcipher.git"
  env :std

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles/homebrew-ub/db4ssqlcipherub"
    rebuild 1
    sha256 cellar: :any, arm64_ventura: "3f8a5f6c9f96faff86685cb959980567d4fc9cae9a792b552fabca37c36cfb96"
  end

  depends_on arch: :arm64
  depends_on "db4ssqlcipherub-x86_64"
  depends_on "db4sopensslub@3-arm64"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-tempstore=yes
      --with-crypto-lib=#{Formula["db4sopensslub@3-arm64"]}
      --enable-load-extension
      --disable-tcl
    ]

    # Build with full-text search enabled"
    ENV.append "CPPFLAGS", "-DSQLCIPHER_CRYPTO_OPENSSL"
    ENV.append "CPPFLAGS", "-DSQLITE_HAS_CODEC"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_STAT4"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_JSON1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_FTS3"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_FTS3_PARENTHESIS"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_FTS5"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_GEOPOLY"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_RTREE"
    ENV.append "CPPFLAGS", "-DSQLITE_SOUNDEX"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_MEMORY_MANAGEMENT=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_SNAPSHOT=1"

    system "./configure", *args
    system "make"
    system "make", "install"
    system "lipo", "-create", "-output", "#{lib}/libsqlcipher.0.dylib", "#{lib}/libsqlcipher.0.dylib", "/opt/homebrew/opt/db4ssqlcipherub-x86_64/lib/libsqlcipher.0.dylib"
    system "lipo", "-create", "-output", "#{lib}/libsqlcipher.a", "#{lib}/libsqlcipher.a", "/opt/homebrew/opt/db4ssqlcipherub-x86_64/lib/libsqlcipher.a"
    rm "#{lib}/libsqlcipher.dylib"
    ln_s "#{lib}/libsqlcipher.0.dylib", "#{lib}/libsqlcipher.dylib"
  end

  test do
    path = testpath/"school.sql"
    path.write <<~EOS
      create table students (name text, age integer);
      insert into students (name, age) values ('Bob', 14);
      insert into students (name, age) values ('Sue', 12);
      insert into students (name, age) values ('Tim', json_extract('{"age": 13}', '$.age'));
      select name from students order by age asc;
    EOS

    names = shell_output("#{bin}/sqlcipher < #{path}").strip.split("\n")
    assert_equal %w[Sue Tim Bob], names
  end
end
