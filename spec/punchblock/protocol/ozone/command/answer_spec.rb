require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Command
        describe Answer do
          it 'registers itself' do
            OzoneNode.class_from_registration(:answer, 'urn:xmpp:ozone:1').should == Answer
          end

          it_should_behave_like 'command_headers'
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
