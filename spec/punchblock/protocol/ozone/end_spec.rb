require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe End do
        it 'registers itself' do
          Event.class_from_registration(:end, 'urn:xmpp:ozone:1').should == End
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<end xmlns="urn:xmpp:ozone:1">
  <timeout />
</end>
            MESSAGE
          end

          subject { Event.import parse_stanza(stanza).root, '9f00061', '1' }

          it { should be_instance_of End }

          it_should_behave_like 'event'

          its(:reason) { should == :timeout }
          its(:xmlns) { should == 'urn:xmpp:ozone:1' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
