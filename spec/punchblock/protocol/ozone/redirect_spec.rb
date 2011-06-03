require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Redirect do
        # subject { Redirect.new 'tel:+14045551234' }

        # its(:to_xml) { should == '<redirect xmlns="urn:xmpp:ozone:1" to="tel:+14045551234"/>' }

        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:redirect, 'urn:xmpp:ozone:1').should == Redirect
        end

        it 'ensures an redirect node is present on create' do
          subject.find_first('/iq/ns:redirect', :ns => Redirect.registered_ns).should_not be_nil
        end

        it 'ensures a redirect node exists when calling #redirect' do
          subject.remove_children :redirect
          subject.find_first('/iq/ns:redirect', :ns => Redirect.registered_ns).should be_nil

          subject.redirect.should_not be_nil
          subject.find_first('/iq/ns:redirect', :ns => Redirect.registered_ns).should_not be_nil
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <redirect to='tel:+14152226789' xmlns='urn:xmpp:ozone:1'>
    <!-- Sample Headers (optional) -->
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </redirect>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Redirect }

          it_should_behave_like 'message'

          its(:redirect_to) { should == 'tel:+14152226789' }
          its(:headers) { should == {:x_skill => 'agent', :x_customer_id => '8877'} }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
