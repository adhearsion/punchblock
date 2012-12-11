# encoding: utf-8

require 'punchblock'
require 'countdownlatch'
require 'logger'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

Thread.abort_on_exception = true

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :suite do |variable|
    Punchblock.logger = Logger.new(STDOUT)
    Punchblock.logger.define_singleton_method :trace, Punchblock.logger.method(:debug)
  end

  config.after :each do
    Object.const_defined?(:Celluloid) && Celluloid.shutdown
  end
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS
end

def import_stanza(xml)
  Blather::Stanza.import parse_stanza(xml).root
end

def stub_uuids(value)
  RubyAMI.stub :new_uuid => value
  Punchblock.stub :new_uuid => value
end

# FIXME: change this to rayo_event?  It can be ambigous
shared_examples_for 'event' do
  its(:target_call_id)  { should be == '9f00061' }
  its(:component_id)    { should be == '1' }
end

shared_examples_for 'command_headers' do
  it 'takes a hash of keys and values for headers' do
    headers = { :x_skill => 'agent', :x_customer_id => '8877' }

    control = [ Punchblock::Header.new(:x_skill, 'agent'), Punchblock::Header.new(:x_customer_id, '8877')]

    di = subject.class.new :headers => headers
    di.headers.should have(2).items
    di.headers.each { |i| control.include?(i).should be_true }
  end
end

shared_examples_for 'event_headers' do
  its(:headers) { should be == [Punchblock::Header.new('X-skill', 'agent'), Punchblock::Header.new('X-customer-id', '8877')]}
  its(:headers_hash) { should be == {:x_skill => 'agent', :x_customer_id => '8877'} }
end

shared_examples_for 'key_value_pairs' do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<#{element_name} name='boo' value='bah' />"
    h = described_class.new n.root
    h.name.should be == 'boo'
    h.value.should be == 'bah'
  end

  it 'has a name attribute' do
    n = described_class.new :boo, 'bah'
    n.name.should be == 'boo'
    n.name = :foo
    n.name.should be == 'foo'
  end

  it 'has a value param' do
    n = described_class.new :boo, 'en'
    n.value.should be == 'en'
    n.value = 'de'
    n.value.should be == 'de'
  end

  it 'can determine equality' do
    a = described_class.new :boo, 'bah'
    a.should be == described_class.new(:boo, 'bah')
    a.should_not be == described_class.new(:bah, 'bah')
    a.should_not be == described_class.new(:boo, 'boo')
  end
end
