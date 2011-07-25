require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Accept do
          it 'registers itself' do
            RayoNode.class_from_registration(:accept, 'urn:xmpp:rayo:1').should == Accept
          end

          it_should_behave_like 'command_headers'
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
