# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Answered do
      it 'registers itself' do
        RayoNode.class_from_registration(:answered, 'urn:xmpp:rayo:1').should == Answered
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<answered xmlns='urn:xmpp:rayo:1'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="x-skill" value="agent" />
  <header name="x-customer-id" value="8877" />
</answered>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Answered }

        it_should_behave_like 'event'
        it_should_behave_like 'event_headers'

        its(:xmlns) { should == 'urn:xmpp:rayo:1' }
      end

      describe "when setting options in initializer" do
        subject do
          Answered.new :headers => { :x_skill => "agent", :x_customer_id => "8877" }
        end

        it_should_behave_like 'event_headers'
      end
    end
  end
end # Punchblock
