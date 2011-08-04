require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Dial do

          it 'registers itself' do
            RayoNode.class_from_registration(:dial, 'urn:xmpp:rayo:1').should == Dial
          end

          describe "when setting options in initializer" do
            let(:join_params) { {:other_call_id => 'abc123'} }

            subject { Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 }, :join => join_params }

            it_should_behave_like 'command_headers'

            its(:to)    { should == 'tel:+14155551212' }
            its(:from)  { should == 'tel:+13035551212' }
            its(:join)  { should == Join.new(join_params) }
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
