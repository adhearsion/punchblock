require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Answer do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:answer, 'urn:xmpp:ozone:1').should == Answer
        end

        it 'ensures an answer node is present on create' do
          subject.find_first('/iq/ns:answer', :ns => Answer.registered_ns).should_not be_nil
        end

        it 'ensures a answer node exists when calling #answer' do
          subject.remove_children :answer
          subject.find_first('/iq/ns:answer', :ns => Answer.registered_ns).should be_nil

          subject.answer.should_not be_nil
          subject.find_first('/iq/ns:answer', :ns => Answer.registered_ns).should_not be_nil
        end

        # it 'sets the host if requested' do
        #   aff = Answer.new :get, 'answer.jabber.local'
        #   aff.to.should == Blather::JID.new('answer.jabber.local')
        # end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <answer xmlns='urn:xmpp:ozone:1'>
    <!-- Sample Headers (optional) -->
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </answer>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Answer }

          it_should_behave_like 'message'

          its(:headers) { should == {:x_skill => 'agent', :x_customer_id => "8877"} }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
