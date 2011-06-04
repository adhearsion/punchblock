require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Offer do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:offer, 'urn:xmpp:ozone:1').should == Offer
        end

        it 'ensures an offer node is present on create' do
          subject.find_first('/iq/ns:offer', :ns => Offer.registered_ns).should_not be_nil
        end

        it 'ensures a offer node exists when calling #offer' do
          subject.remove_children :offer
          subject.find_first('/iq/ns:offer', :ns => Offer.registered_ns).should be_nil

          subject.offer.should_not be_nil
          subject.find_first('/iq/ns:offer', :ns => Offer.registered_ns).should_not be_nil
        end

        describe "when setting options in initializer" do
          subject { Offer.new 'tel:+18003211212', 'tel:+13058881212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

          its(:offer_to) { should == 'tel:+18003211212' }
          its(:offer_from) { should == 'tel:+13058881212' }
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='16577@app.ozone.net/1' from='9f00061@call.ozone.net/1' id='1234'>
  <offer xmlns='urn:xmpp:ozone:1'
      to='tel:+18003211212'
      from='tel:+13058881212'>
    <!-- Signaling (e.g. SIP) Headers -->
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </offer>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Offer }

          def num_arguments_pre_options
            2
          end

          it_should_behave_like 'message'
          it_should_behave_like 'headers'

          its(:offer_to) { should == 'tel:+18003211212' }
          its(:offer_from) { should == 'tel:+13058881212' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
