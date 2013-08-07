# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "facebook_test_users/version"

Gem::Specification.new do |s|
  s.name        = "facebook_test_users"
  s.version     = FacebookTestUsers::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sam Merritt"]
  s.email       = ["spam@andcheese.org"]
  s.homepage    = "https://github.com/smerritt/facebook_test_users"
  s.summary     = %q{A CLI tool + library for manipulating Facebook test users}
  s.description =
    "Test users are extremely handy for testing your Facebook applications. This gem " +
    "lets you create and delete users and make them befriend one another. " +
    "It is intended to make testing your Facebook applications slightly less painful."

  s.rubyforge_project = "facebook_test_users"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rest-client', '>= 1.6.1'
  s.add_dependency 'thor',        '>= 0.14.6'
  s.add_dependency 'multi_json'
  s.add_dependency 'heredoc_unindent'
  s.add_dependency 'launchy'

  s.add_development_dependency 'fakeweb',         '~>1.3.0'
  s.add_development_dependency 'fakeweb-matcher', '~>1.2.2'
  s.add_development_dependency 'rspec',           '>= 2.3.0'
  s.add_development_dependency 'json'
end
