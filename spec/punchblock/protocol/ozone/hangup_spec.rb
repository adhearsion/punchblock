require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Hangup do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:hangup, 'urn:xmpp:ozone:1').should == Hangup
        end

        it 'ensures a hangup node is present on create' do
          subject.find_first('/iq/ns:hangup', :ns => Hangup.registered_ns).should_not be_nil
        end

        it 'ensures a hangup node exists when calling #hangup' do
          subject.remove_children :hangup
          subject.find_first('/iq/ns:hangup', :ns => Hangup.registered_ns).should be_nil

          subject.hangup.should_not be_nil
          subject.find_first('/iq/ns:hangup', :ns => Hangup.registered_ns).should_not be_nil
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq from='blah@blah.com' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1' id='12323'>
  <hangup xmlns="urn:xmpp:ozone:1">
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </end>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Hangup }

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
