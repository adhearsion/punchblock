require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Redirect do

        it 'registers itself' do
          Command.class_from_registration(:redirect, 'urn:xmpp:ozone:1').should == Redirect
        end

        describe "when setting options in initializer" do
          subject { Redirect.new :to => 'tel:+14045551234', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

          it_should_behave_like 'command_headers'

          its(:to) { should == 'tel:+14045551234' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
