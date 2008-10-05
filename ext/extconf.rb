def die(msg)
  $stderr.puts "**** ERROR: #{msg}"
  exit 1
end

# rewrite MYSQL_RUBY_VERSION in motto_mysql.h
require 'mysql.so'
unless Mysql::VERSION >= 20704
  die "mysql-ruby is too old (required >= 2.7.4)."
end
filename = 'motto_mysql.h'
s = File.open(filename) {|f| f.read }
s.sub! /^(\#define MYSQL_RUBY_VERSION\s+).*?$/, "\\1#{Mysql::VERSION}"
File.open(filename, 'wb') {|f| f.write s }


require 'mkmf'

if /mswin32/ =~ RUBY_PLATFORM
  inc, lib = dir_config('mysql')
  have_library("libmysql") or die "can't find libmysql."
elsif mc = with_config('mysql-config') then
  mc = 'mysql_config' if mc == true
  cflags = `#{mc} --cflags`.chomp  ; $? == 0 or die "can't detect cflags."
  libs   = `#{mc} --libs`.chomp    ; $? == 0 or die "can't detect libs."
  $CPPFLAGS += ' ' + cflags
  $libs = libs + " " + $libs
else
  $stderr.puts "Trying to detect MySQL configuration with mysql_config..."
  if (cflags = `mysql_config --cflags`.strip) && $? == 0 &&
     (libs   = `mysql_config --libs`.strip)   && $? == 0
    $stderr.puts "Succeeded to detect MySQL configuration with mysql_config."
    $CPPFLAGS += ' ' + cflags.strip
    $libs = libs.strip + " " + $libs
  else
    $stderr.puts "Failed to detect MySQL configuration with mysql_config."
    $stderr.puts "Trying to detect MySQL client library..."
    inc, lib = dir_config('mysql', '/usr/local')
    libs = ['m', 'z', 'socket', 'nsl', 'mygcc']
    while not find_library('mysqlclient', 'mysql_query', lib, "#{lib}/mysql") do
      die "can't find mysql client library." if libs.empty?
      have_library(libs.shift)
    end
  end
end

have_func('mysql_ssl_set')
have_func('rb_str_set_len')


## define HAVE_MYSQL_H if mysql.h is found
have_header('mysql.h') or have_header('mysql/mysql.h') or die "can't find 'mysql.h'."


#if have_header('mysql.h') then
#  src = "#include <errmsg.h>\n#include <mysqld_error.h>\n"
#elsif have_header('mysql/mysql.h') then
#  src = "#include <mysql/errmsg.h>\n#include <mysql/mysqld_error.h>\n"
#else
#  die "can't find 'mysql.h'."
#end

## make mysql constant
#File.open("conftest.c", "w") do |f|
#  f.puts src
#end
#
#if defined? cpp_command then
#  cpp = Config.expand(cpp_command(''))
#else
#  cpp = Config.expand sprintf(CPP, $CPPFLAGS, $CFLAGS, '')
#end
#if /mswin32/ =~ RUBY_PLATFORM && !/-E/.match(cpp)
#  cpp << " -E"
#end
#unless system "#{cpp} > confout" then
#  die "can't compile test source."
#end
#
## add '#define ulong unsigned long' to mysql.c on MacOS X
#if /darwin/ =~ RUBY_PLATFORM && /i686/ =~ RUBY_PLATFORM
#  definition = "#define ulong unsigned long\n"
#  s = File.open('mysql.c') {|f| f.read }
#  unless s.index(definition)
#    print "add '#{definition.chomp}' to mysql.c..."
#    File.open('mysql.c', 'w') {|f| f.write(definition + s) }
#    puts "done."
#  end
#end
#
#File.unlink "conftest.c"
#
#error_syms = []
#IO.foreach('confout') do |l|
#  next unless l =~ /errmsg\.h|mysqld_error\.h/
#  fn = l.split(/\"/)[1]
#  IO.foreach(fn) do |m|
#    if m =~ /^#define\s+([CE]R_[0-9A-Z_]+)/ then
#      error_syms << $1
#    end
#  end
#end
#File.unlink 'confout'
#error_syms.uniq!
#
#File.open('error_const.h', 'w') do |f|
#  error_syms.each do |s|
#    f.puts "    rb_define_mysql_const(#{s});"
#  end
#end
#
#create_makefile("mysql")

create_makefile("motto_mysql")
