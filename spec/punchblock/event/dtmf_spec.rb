require 'spec_helper'

module Punchblock
  class Event
    describe DTMF do
      it 'registers itself' do
        RayoNode.class_from_registration(:dtmf, 'urn:xmpp:rayo:1').should == DTMF
      end

      describe "from a stanza" do
        let(:stanza) { "<dtmf xmlns='urn:xmpp:rayo:1' signal='#' />" }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of DTMF }

        it_should_behave_like 'event'

        its(:signal) { should == '#' }
        its(:xmlns) { should == 'urn:xmpp:rayo:1' }
      end

      describe "when setting options in initializer" do
        subject do
          DTMF.new :signal => '#'
        end

        its(:signal) { should == '#' }
      end
    end
  end
end # Punchblock
