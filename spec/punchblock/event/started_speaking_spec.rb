# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe StartedSpeaking do
      it 'registers itself' do
        RayoNode.class_from_registration(:'started-speaking', 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let :stanza do
          '<started-speaking xmlns="urn:xmpp:rayo:1" call-id="x0yz4ye-lx7-6ai9njwvw8nsb"/>'
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'

        its(:call_id) { should be == "x0yz4ye-lx7-6ai9njwvw8nsb" }
      end

      describe "when setting options in initializer" do
        subject do
          described_class.new :call_id => 'abc123'
        end

        its(:call_id) { should be == 'abc123' }
      end
    end
  end
end
