require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Unjoin do

          it 'registers itself' do
            RayoNode.class_from_registration(:unjoin, 'urn:xmpp:rayo:1').should == Unjoin
          end

          describe "when setting options in initializer" do
            subject { Unjoin.new :other_call_id => 'abc123', :mixer_id => 'blah' }

            its(:other_call_id) { should == 'abc123' }
            its(:mixer_id)      { should == 'blah' }
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
