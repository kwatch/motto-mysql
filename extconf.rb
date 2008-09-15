require 'mkmf'

def die(msg)
  $stderr.puts "**** ERROR: #{msg}"
  exit 1
end

if /mswin32/ =~ RUBY_PLATFORM
  inc, lib = dir_config('mysql')
  die "can't find libmysql." unless have_library("libmysql")
elsif mc = with_config('mysql-config') then
  mc = 'mysql_config' if mc == true
  cflags = `#{mc} --cflags`.chomp
  die "can't detect cflags." if $? != 0
  libs = `#{mc} --libs`.chomp
  die "can't detect libs." if $? != 0
  $CPPFLAGS += ' ' + cflags
  $libs = libs + " " + $libs
else
  inc, lib = dir_config('mysql', '/usr/local')
  libs = ['m', 'z', 'socket', 'nsl', 'mygcc']
  while not find_library('mysqlclient', 'mysql_query', lib, "#{lib}/mysql") do
    die "can't find mysql client library." if libs.empty?
    have_library(libs.shift)
  end
end

have_func('mysql_ssl_set')
have_func('rb_str_set_len')

if have_header('mysql.h') then
  src = "#include <errmsg.h>\n#include <mysqld_error.h>\n"
elsif have_header('mysql/mysql.h') then
  src = "#include <mysql/errmsg.h>\n#include <mysql/mysqld_error.h>\n"
else
  die "can't find 'mysql.h'."
end

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
