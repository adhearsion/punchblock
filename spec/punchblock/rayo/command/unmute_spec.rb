require 'spec_helper'

module Punchblock
  class Rayo
    module Command
      describe Unmute do
        it 'registers itself' do
          RayoNode.class_from_registration(:unmute, 'urn:xmpp:rayo:1').should == Unmute
        end
      end
    end
  end # Rayo
end # Punchblock
