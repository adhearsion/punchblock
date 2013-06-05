# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Ringing do
      it 'registers itself' do
        RayoNode.class_from_registration(:ringing, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<ringing xmlns='urn:xmpp:rayo:1'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</ringing>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers provided" do
          let(:stanza) { '<ringing xmlns="urn:xmpp:rayo:1"/>' }

          its(:headers) { should == {} }
        end
      end

      describe "when setting options in initializer" do
        subject { described_class.new headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }
      end
    end
  end
end
