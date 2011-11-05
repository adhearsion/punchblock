require 'spec_helper'

module Punchblock
  module Command
    describe Answer do
      it 'registers itself' do
        RayoNode.class_from_registration(:answer, 'urn:xmpp:rayo:1').should == Answer
      end

      it_should_behave_like 'command_headers'

      describe "from a stanza" do
        let(:stanza) { '<answer xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Answer }
      end
    end
  end
end # Punchblock
