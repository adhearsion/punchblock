require 'spec_helper'

module Punchblock
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

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<unjoin xmlns="urn:xmpp:rayo:1"
      call-id="abc123"
      mixer-id="blah" />
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Unjoin }

        its(:other_call_id) { should == 'abc123' }
        its(:mixer_id)      { should == 'blah' }
      end
    end
  end
end # Punchblock
