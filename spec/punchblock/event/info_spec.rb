require 'spec_helper'

module Punchblock
  class Event
    describe Info do
      it 'registers itself' do
        RayoNode.class_from_registration(:info, 'urn:xmpp:rayo:1').should == Info
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<info xmlns='urn:xmpp:rayo:1'>
  <something/>
</info>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Info }

        it_should_behave_like 'event'

        its(:event_name) { should == :something }
        its(:xmlns) { should == 'urn:xmpp:rayo:1' }
      end
    end
  end
end # Punchblock
