# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Redirect do
      it 'registers itself' do
        RayoNode.class_from_registration(:redirect, 'urn:xmpp:rayo:1').should be == Redirect
      end

      describe "when setting options in initializer" do
        subject { Redirect.new :to => 'tel:+14045551234', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

        it_should_behave_like 'command_headers'

        its(:to) { should be == 'tel:+14045551234' }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<redirect xmlns='urn:xmpp:rayo:1'
    to='tel:+14045551234'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="x-skill" value="agent" />
  <header name="x-customer-id" value="8877" />
</redirect>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Redirect }

        it_should_behave_like 'command_headers'

        its(:to) { should be == 'tel:+14045551234' }
      end
    end # Redirect
  end # Command
end # Punchblock
