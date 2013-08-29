#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

string = 'FullyBooted'
FULLY_BOOTED = 'fullybooted'

Benchmark.ips do |ips|
  ips.report("downcase+compare") { string.downcase == 'fullybooted' }
  ips.report("casecmp") { string.casecmp('fullybooted') == 0 }
  ips.report("casecmp w/ constant") { string.casecmp(FULLY_BOOTED) == 0 }
end
