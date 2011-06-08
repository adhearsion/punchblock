require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Complete do
        it 'registers itself' do
          Event.class_from_registration(:complete, 'urn:xmpp:ozone:ext:1').should == Complete
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:ozone:ext:1'>
  <success mode="speech" confidence="0.45" xmlns='urn:xmpp:ozone:ask:complete:1'>
    <interpretation>1234</interpretation>
    <utterance>one two three four</utterance>
  </success>
</complete>
            MESSAGE
          end

          subject { Event.import parse_stanza(stanza).root, '9f00061', '1' }

          it { should be_instance_of Complete }

          it_should_behave_like 'event'

          its(:complete_type) { should == :success }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
