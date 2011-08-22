require 'spec_helper'

module Punchblock
  module Command
    describe Redirect do
      it 'registers itself' do
        RayoNode.class_from_registration(:redirect, 'urn:xmpp:rayo:1').should == Redirect
      end

      describe "when setting options in initializer" do
        subject { Redirect.new :to => 'tel:+14045551234', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

        it_should_behave_like 'command_headers'

        its(:to) { should == 'tel:+14045551234' }
      end
    end # Redirect
  end # Command
end # Punchblock
