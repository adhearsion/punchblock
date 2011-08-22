require 'spec_helper'

module Punchblock
  module Event
    describe Joined do
      it 'registers itself' do
        RayoNode.class_from_registration(:joined, 'urn:xmpp:rayo:1').should == Joined
      end

      describe "from a stanza" do
        let(:stanza) { '<joined xmlns="urn:xmpp:rayo:1" call-id="b" mixer-id="m" />' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Joined }

        it_should_behave_like 'event'

        its(:other_call_id) { should == 'b' }
        its(:mixer_id)      { should == 'm' }
        its(:xmlns)         { should == 'urn:xmpp:rayo:1' }
      end

      describe "when setting options in initializer" do
        subject { Joined.new :other_call_id => 'abc123', :mixer_id => 'blah' }

        its(:other_call_id) { should == 'abc123' }
        its(:mixer_id)      { should == 'blah' }
      end
    end
  end
end # Punchblock
