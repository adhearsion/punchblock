require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      describe Ref do
        it 'registers itself' do
          RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1').should == Ref
        end

        describe "from a stanza" do
          let(:stanza) { "<ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />" }

          subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

          it { should be_instance_of Ref }

          it_should_behave_like 'event'

          its(:id) { should == 'fgh4590' }
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
