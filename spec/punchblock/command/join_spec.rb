require 'spec_helper'

module Punchblock
  module Command
    describe Join do

      it 'registers itself' do
        RayoNode.class_from_registration(:join, 'urn:xmpp:rayo:1').should == Join
      end

      describe "when setting options in initializer" do
        subject { Join.new :other_call_id => 'abc123', :mixer_id => 'blah', :direction => :duplex, :media => :bridge }

        its(:other_call_id) { should == 'abc123' }
        its(:mixer_id)      { should == 'blah' }
        its(:direction)     { should == :duplex }
        its(:media)         { should == :bridge }
      end
    end
  end
end # Punchblock
