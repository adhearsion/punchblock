require 'spec_helper'

module Punchblock
  module Command
    describe Answer do
      it 'registers itself' do
        RayoNode.class_from_registration(:answer, 'urn:xmpp:rayo:1').should == Answer
      end

      it_should_behave_like 'command_headers'
    end
  end
end # Punchblock
