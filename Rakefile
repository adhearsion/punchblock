require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

require 'rspec/core'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = '--color'
  spec.ruby_opts = "-w -r./spec/capture_warnings"
end

task :default => :spec
task :ci => ['ci:setup:rspec', :spec]
task :hudson => :ci

require 'yard'
YARD::Rake::YardocTask.new

task :encodeify do
  Dir['{lib,spec}/**/*.rb'].each do |filename|
    File.open filename do |file|
      first_line = file.first
      if first_line == "# encoding: utf-8\n"
        puts "#{filename} is utf-8"
      else
        puts "Making #{filename} utf-8..."
        File.unlink filename
        File.open filename, "w" do |new_file|
          new_file.write "# encoding: utf-8\n\n"
          new_file.write first_line
          new_file.write file.read
        end
      end
    end
  end
end
