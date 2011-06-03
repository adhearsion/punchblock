$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'punchblock'
require 'flexmock'
require 'active_support/all'

RSpec.configure do |config|
  config.mock_with :flexmock
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml
end

shared_examples_for 'message' do
  its(:call_id) { should == '9f00061' }
  its(:command_id) { should == '1' }
end
