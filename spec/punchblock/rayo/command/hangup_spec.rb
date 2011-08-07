require 'spec_helper'

module Punchblock
  class Rayo
    module Command
      describe Hangup do
        it 'registers itself' do
          RayoNode.class_from_registration(:hangup, 'urn:xmpp:rayo:1').should == Hangup
        end

        it_should_behave_like 'command_headers'
      end
    end
  end # Rayo
end # Punchblock
