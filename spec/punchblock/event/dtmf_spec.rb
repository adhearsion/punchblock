# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe DTMF do
      it 'registers itself' do
        RayoNode.class_from_registration(:dtmf, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let(:stanza) { "<dtmf xmlns='urn:xmpp:rayo:1' signal='#' />" }

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'

        its(:signal) { should be == '#' }
      end

      describe "when setting options in initializer" do
        subject do
          described_class.new :signal => '#'
        end

        its(:signal) { should be == '#' }
      end
    end
  end
end
