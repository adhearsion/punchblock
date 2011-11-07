require 'spec_helper'

module Punchblock
  module Command
    describe Mute do
      it 'registers itself' do
        RayoNode.class_from_registration(:mute, 'urn:xmpp:rayo:1').should == Mute
      end

      describe "from a stanza" do
        let(:stanza) { '<mute xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Mute }
      end
    end
  end
end # Punchblock
