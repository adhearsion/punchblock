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

          def num_arguments_pre_options
            0
          end

          it_should_behave_like 'message'
          it_should_behave_like 'headers'
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
