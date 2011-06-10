require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Hangup do
        it 'registers itself' do
          Command.class_from_registration(:hangup, 'urn:xmpp:ozone:1').should == Hangup
        end

        it_should_behave_like 'command_headers'
      end
    end # Ozone
  end # Protocol
end # Punchblock
