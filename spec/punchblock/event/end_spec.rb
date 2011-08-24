require 'spec_helper'

module Punchblock
  class Event
    describe End do
      it 'registers itself' do
        RayoNode.class_from_registration(:end, 'urn:xmpp:rayo:1').should == End
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<end xmlns="urn:xmpp:rayo:1">
  <timeout />
</end>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of End }

        it_should_behave_like 'event'

        its(:reason) { should == :timeout }
        its(:xmlns) { should == 'urn:xmpp:rayo:1' }
      end
    end
  end
end # Punchblock
