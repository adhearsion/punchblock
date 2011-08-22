require 'spec_helper'

module Punchblock
  module Command
    describe Mute do
      it 'registers itself' do
        RayoNode.class_from_registration(:mute, 'urn:xmpp:rayo:1').should == Mute
      end
    end
  end
end # Punchblock
