require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Command
        describe Dial do

          it 'registers itself' do
            OzoneNode.class_from_registration(:dial, 'urn:xmpp:ozone:1').should == Dial
          end

          describe "when setting options in initializer" do
            subject { Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

            it_should_behave_like 'command_headers'

            its(:to) { should == 'tel:+14155551212' }
            its(:from) { should == 'tel:+13035551212' }
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
