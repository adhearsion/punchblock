require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Answer do
        it 'registers itself' do
          Command.class_from_registration(:answer, 'urn:xmpp:ozone:1').should == Answer
        end

        it_should_behave_like 'command_headers'
      end
    end # Ozone
  end # Protocol
end # Punchblock
