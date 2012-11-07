# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Ringing do
      it 'registers itself' do
        RayoNode.class_from_registration(:ringing, 'urn:xmpp:rayo:1').should be == Ringing
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

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Ringing }

        it_should_behave_like 'event'
        it_should_behave_like 'event_headers'

        its(:xmlns) { should be == 'urn:xmpp:rayo:1' }
      end

      describe "when setting options in initializer" do
        subject do
          Ringing.new :headers => { :x_skill => "agent", :x_customer_id => "8877" }
        end

        it_should_behave_like 'command_headers'
      end
    end
  end
end # Punchblock
