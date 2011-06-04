require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Complete do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:complete, 'urn:xmpp:ozone:ext:1').should == Complete
        end

        it 'ensures an complete node is present on create' do
          subject.find_first('/iq/ns:complete', :ns => Complete.registered_ns).should_not be_nil
        end

        it 'ensures a complete node exists when calling #complete' do
          subject.remove_children :complete
          subject.find_first('/iq/ns:complete', :ns => Complete.registered_ns).should be_nil

          subject.complete.should_not be_nil
          subject.find_first('/iq/ns:complete', :ns => Complete.registered_ns).should_not be_nil
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='16577@app.ozone.net/1' from='9f00061@call.ozone.net/1'>
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <success mode="speech" confidence="0.45" xmlns='urn:xmpp:ozone:ask:complete:1'>
      <interpretation>1234</interpretation>
      <utterance>one two three four</utterance>
    </success>
  </complete>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Complete }

          it_should_behave_like 'message'

          its(:complete_type) { should == :success }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
