require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Dial do

        it 'registers itself' do
          Command.class_from_registration(:dial, 'urn:xmpp:ozone:1').should == Dial
        end

        describe "when setting options in initializer" do
          subject { Dial.new 'tel:+14155551212', 'tel:+13035551212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

          def num_arguments_pre_options
            2
          end

          it_should_behave_like 'command_headers'

          its(:to) { should == 'tel:+14155551212' }
          its(:from) { should == 'tel:+13035551212' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
