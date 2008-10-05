require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name    = "motto-mysql"
  s.author  = "makoto kuwata"
  s.email   = "kwa.at.kuwata-lab.com"
  s.version = "0.1.0"
  #s.platform    = Gem::Platform::RUBY
  s.homepage = "http://rubyforge.org/projects/motto-mysql/"
  s.summary = "an extension to enhance 'mysql-ruby' library."
  s.rubyforge_project = "motto-mysql"
  s.description = <<END
Motto-mysql is a complementary library to enhance 'mysql-ruby' library.
It adds some methods into Mysql::Result and Mysql::Stmt classes.
Motto-mysql requires mysql-ruby 2.7.4 or later (recommended 2.7.5 or later).
END
  s.files = ["README.rdoc", "setup.rb"] + Dir.glob("ext/**/*")
  #s.executable = "bin/xxx"
  #s.bindir     = "bin"
  #s.test_file  = "test/test_motto_mysql.rb"
  #s.add_dependency("mysql-ruby", [">= 2.7.4"])
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.date = "2008-10-05"
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = ["README.rdoc"]
  #s.has_rdoc = true
  s.rdoc_options = ["--quiet", "--title", "Motto-mysql Reference", "--main", "README.rdoc", "--inline-source"]
  #s.require_paths = ["lib"]
  #s.rubygems_version = "1.2.0"
end

# Quick fix for Ruby 1.8.3 / YAML bug   (thanks to Ross Bamford)
if (RUBY_VERSION == '1.8.3')
  def spec.to_yaml
    out = super
    out = '--- ' + out unless out =~ /^---/
    out
  end
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
