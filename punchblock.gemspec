# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "punchblock/version"

Gem::Specification.new do |s|
  s.name        = %q{punchblock}
  s.version     = Punchblock::VERSION
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ["MIT"]
  s.authors     = ["Jason Goecke", "Ben Klang", "Ben Langfeld"]
  s.email       = %q{punchblock@adhearsion.com}
  s.homepage    = %q{http://github.com/adhearsion/punchblock}
  s.summary     = "Punchblock is a telephony middleware library"
  s.description = "Like Rack is to Rails and Sinatra, Punchblock provides a consistent API on top of several underlying third-party call control protocols."

  s.rubyforge_project = "punchblock"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.7") if s.respond_to? :required_rubygems_version=

  s.add_runtime_dependency %q<niceogiri>, [">= 0.0.4"]
  s.add_runtime_dependency %q<blather>, [">= 0.5.3"]
  s.add_runtime_dependency %q<pry>, [">= 0.8.3"]
  s.add_runtime_dependency %q<activesupport>, [">= 2.1.0"]
  s.add_runtime_dependency %q<state_machine>, [">= 1.0.1"]
  s.add_runtime_dependency %q<future-resource>, [">= 0.0.2"]
  s.add_runtime_dependency %q<has-guarded-handlers>, [">= 0.0.3"]

  s.add_development_dependency %q<bundler>, ["~> 1.0.0"]
  s.add_development_dependency %q<rspec>, ["~> 2.3.0"]
  s.add_development_dependency %q<ci_reporter>, [">= 1.6.3"]
  s.add_development_dependency %q<yard>, ["~> 0.6.0"]
  s.add_development_dependency %q<rcov>, [">= 0"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<mocha>, [">= 0"]
  s.add_development_dependency %q<i18n>, [">= 0"]
  s.add_development_dependency %q<countdownlatch>, [">= 0"]
end
