# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Unmute do
      it 'registers itself' do
        RayoNode.class_from_registration(:unmute, 'urn:xmpp:rayo:1').should be == Unmute
      end

      describe "from a stanza" do
        let(:stanza) { '<unmute xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Unmute }
      end
    end
  end
end # Punchblock
