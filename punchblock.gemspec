# -*- encoding: utf-8 -*-
require 'date'

Gem::Specification.new do |s|
  s.name = %q{punchblock}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason Goecke", "Ben Klang", "Ben Langfeld"]
  s.date = Date.today.to_s
  s.default_executable = %q{punchblock}
  s.description = "Like Rack is to Rails and Sinatra, Punchblock provides a consistent API on top of several underlying third-party call control protocols."
  s.email = %q{punchblock@adhearsion.com}
  s.executables = ["punchblock"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "bin/punchblock",
    "lib/nokogiri_hash.rb",
    "lib/punchblock.rb",
    "lib/punchblock/call.rb",
    "lib/punchblock/dsl.rb",
    "lib/punchblock/protocol/ozone.rb",
    "lib/punchblock/transport/xmpp.rb",
    "spec/protocol/ozone_messages_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/adhearsion/punchblock}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = "Punchblock is a telephony middleware library"
  s.test_files = [
    "spec/protocol/ozone_messages_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<blather>, [">= 0"])
      s.add_runtime_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<blather>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<blather>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<blather>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<blather>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

