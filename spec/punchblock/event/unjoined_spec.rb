# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Unjoined do
      it 'registers itself' do
        RayoNode.class_from_registration(:unjoined, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let(:stanza) { '<unjoined xmlns="urn:xmpp:rayo:1" call-uri="b" mixer-name="m" />' }

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'

        its(:call_uri)    { should be == 'b' }
        its(:mixer_name)  { should be == 'm' }
      end

      describe "when setting options in initializer" do
        subject { described_class.new :call_uri => 'abc123', :mixer_name => 'blah' }

        its(:call_uri)    { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
      end
    end
  end
end
