require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "punchblock"
  gem.homepage = "http://github.com/jsgoecke/punchblock"
  gem.license = "MIT"
  gem.summary = "Punchblock is a middleware library for telephony applications."
  gem.description = "Like Rack is to Rails and Sinatra, Punchblock provides a consistent API on top of several underlying third-party call control protocols."
  gem.email = "jsgoecke@voxeo.com"
  gem.authors = ["Jason Goecke", "Ben Klang", "Ben Langfeld"]
  gem.add_runtime_dependency 'blather'
  gem.add_development_dependency 'rspec'
  gem.executables = ["punchblock"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rspec_opts = '--color'
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
