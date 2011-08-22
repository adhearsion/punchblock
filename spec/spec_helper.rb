$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'punchblock'
require 'mocha'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS
end

def import_stanza(xml)
  Blather::Stanza.import parse_stanza(xml).root
end

shared_examples_for 'event' do
  its(:call_id) { should == '9f00061' }
  its(:component_id) { should == '1' }
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
  its(:headers) { should == [Punchblock::Header.new(:x_skill, 'agent'), Punchblock::Header.new(:x_customer_id, '8877')]}
  its(:headers_hash) { should == {:x_skill => 'agent', :x_customer_id => '8877'} }
end
