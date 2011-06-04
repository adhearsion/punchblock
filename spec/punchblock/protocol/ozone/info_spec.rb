require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Info do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:info, 'urn:xmpp:ozone:1').should == Info
        end

        it 'ensures an info node is present on create' do
          subject.find_first('/iq/ns:info', :ns => Info.registered_ns).should_not be_nil
        end

        it 'ensures a info node exists when calling #info' do
          subject.remove_children :info
          subject.find_first('/iq/ns:info', :ns => Info.registered_ns).should be_nil

          subject.info.should_not be_nil
          subject.find_first('/iq/ns:info', :ns => Info.registered_ns).should_not be_nil
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='16577@app.ozone.net/1' from='9f00061@call.ozone.net/1' id='1234'>
  <info xmlns='urn:xmpp:ozone:1'>
    <something/>
  </info>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Info }

          it_should_behave_like 'message'

          its(:event_name) { should == :something }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
