require 'ozone'

RSpec.configure do |config|
  #config.mock_with :flexmock
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
