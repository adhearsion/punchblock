# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Joined do
      it 'registers itself' do
        expect(RayoNode.class_from_registration(:joined, 'urn:xmpp:rayo:1')).to eq(described_class)
      end

      describe "from a stanza" do
        let(:stanza) { '<joined xmlns="urn:xmpp:rayo:1" call-uri="b" mixer-name="m" />' }

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'

        describe '#call_uri' do
          subject { super().call_uri }
          it { should be == 'b' }
        end

        describe '#call_id' do
          subject { super().call_id }
          it { should be == 'b' }
        end

        describe '#mixer_name' do
          subject { super().mixer_name }
          it { should be == 'm' }
        end
      end

      describe "when setting options in initializer" do
        subject { described_class.new :call_uri => 'abc123', :mixer_name => 'blah' }

        describe '#call_uri' do
          subject { super().call_uri }
          it { should be == 'abc123' }
        end

        describe '#call_id' do
          subject { super().call_id }
          it { should be == 'abc123' }
        end

        describe '#mixer_name' do
          subject { super().mixer_name }
          it { should be == 'blah' }
        end
      end
    end
  end
end
