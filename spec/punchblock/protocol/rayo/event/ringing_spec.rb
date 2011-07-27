require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Event
        describe Ringing do
          it 'registers itself' do
            RayoNode.class_from_registration(:ringing, 'urn:xmpp:rayo:1').should == Ringing
          end

          describe "from a stanza" do
            let(:stanza) { '<ringing xmlns="urn:xmpp:rayo:1"/>' }

            subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Ringing }

            it_should_behave_like 'event'

            its(:xmlns) { should == 'urn:xmpp:rayo:1' }
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
