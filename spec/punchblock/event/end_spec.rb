# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe End do
      it 'registers itself' do
        RayoNode.class_from_registration(:end, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<end xmlns="urn:xmpp:rayo:1">
  <timeout />
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</end>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        it_should_behave_like 'event'

        its(:reason) { should be == :timeout }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers or reason provided" do
          let(:stanza) { '<end xmlns="urn:xmpp:rayo:1"/>' }

          its(:reason) { should be_nil}
          its(:headers) { should == {} }
        end
      end

      describe "when setting options in initializer" do
        subject do
          described_class.new reason: :hangup,
                              headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
        end

        its(:reason) { should be == :hangup }
        its(:headers) { should be == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }
      end
    end
  end
end
