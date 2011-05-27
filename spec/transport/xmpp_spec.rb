require 'spec_helper'

describe 'XMPP Transport' do
  before :all do
    @module = Punchblock::Transport::XMPP
  end

  it 'should properly set the Blather logger' do
    transport = @module.new 'unimportant', {:wire_logger => :foo, :username => 1, :password => 1}
    Blather.logger.should be :foo
  end

end