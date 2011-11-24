require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

require 'rspec/core'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = '--color'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rspec_opts = '--color'
end

task :default => :spec
task :ci => ['ci:setup:rspec', :spec]
task :hudson => :ci

require 'yard'
YARD::Rake::YardocTask.new
