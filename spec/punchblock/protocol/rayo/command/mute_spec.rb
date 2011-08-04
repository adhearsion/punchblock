require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Mute do
          it 'registers itself' do
            RayoNode.class_from_registration(:mute, 'urn:xmpp:rayo:1').should == Mute
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
