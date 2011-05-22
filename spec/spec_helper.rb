$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'punchblock'

RSpec.configure do |config|
  #config.mock_with :flexmock
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
