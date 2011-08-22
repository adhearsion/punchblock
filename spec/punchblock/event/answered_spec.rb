require 'spec_helper'

module Punchblock
  module Event
    describe Answered do
      it 'registers itself' do
        RayoNode.class_from_registration(:answered, 'urn:xmpp:rayo:1').should == Answered
      end

      describe "from a stanza" do
        let(:stanza) { '<answered xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Answered }

        it_should_behave_like 'event'

        its(:xmlns) { should == 'urn:xmpp:rayo:1' }
      end
    end
  end
end # Punchblock
