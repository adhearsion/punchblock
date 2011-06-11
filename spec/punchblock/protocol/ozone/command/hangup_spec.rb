require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      module Command
        describe Hangup do
          it 'registers itself' do
            OzoneNode.class_from_registration(:hangup, 'urn:xmpp:ozone:1').should == Hangup
          end

          it_should_behave_like 'command_headers'
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
