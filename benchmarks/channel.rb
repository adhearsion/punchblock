#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'
require 'punchblock/translator/asterisk/channel'

channel_string = 'abc123'
channel = Punchblock::Translator::Asterisk::Channel.new('abc123')

class Wrapper
  def initialize(string)
    @string = string
  end

  def to_s
    @string
  end
end

wrapper = Wrapper.new 'abc123'

Benchmark.ips do |ips|
  ips.report("string nesting") { "SIP/#{channel_string}" }
  ips.report("wrapper nesting") { "SIP/#{wrapper}" }
  ips.report("delegate nesting") { "SIP/#{channel}" }
end
