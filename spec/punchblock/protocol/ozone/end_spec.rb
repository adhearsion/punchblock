require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe End do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:end, 'urn:xmpp:ozone:1').should == End
        end

        it 'ensures an end node is present on create' do
          subject.find_first('/iq/ns:end', :ns => End.registered_ns).should_not be_nil
        end

        it 'ensures a end node exists when calling #end_message' do
          subject.remove_children :end
          subject.find_first('/iq/ns:end', :ns => End.registered_ns).should be_nil

          subject.end_message.should_not be_nil
          subject.find_first('/iq/ns:end', :ns => End.registered_ns).should_not be_nil
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq from='blah@blah.com' from='9f00061@call.ozone.net/1' to='16577@app.ozone.net/1' id='12323'>
  <end xmlns="urn:xmpp:ozone:1">
    <timeout />
  </end>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of End }

          it_should_behave_like 'message'

          its(:reason) { should == :timeout }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
