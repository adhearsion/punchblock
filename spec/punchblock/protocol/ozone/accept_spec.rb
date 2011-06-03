require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Accept do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:accept, 'urn:xmpp:ozone:1').should == Accept
        end

        it 'ensures an accept node is present on create' do
          subject.find_first('/iq/ns:accept', :ns => Accept.registered_ns).should_not be_nil
        end

        it 'ensures a accept node exists when calling #accept' do
          subject.remove_children :accept
          subject.find_first('/iq/ns:accept', :ns => Accept.registered_ns).should be_nil

          subject.accept.should_not be_nil
          subject.find_first('/iq/ns:accept', :ns => Accept.registered_ns).should_not be_nil
        end

        # it 'sets the host if requested' do
        #   aff = Accept.new :get, 'accept.jabber.local'
        #   aff.to.should == Blather::JID.new('accept.jabber.local')
        # end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <accept xmlns='urn:xmpp:ozone:1'>
    <!-- Sample Headers (optional) -->
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </accept>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Accept }

          it_should_behave_like 'message'

          its(:headers) { should == {:x_skill => 'agent', :x_customer_id => '8877'} }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
