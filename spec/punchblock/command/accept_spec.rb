# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Accept do
      it 'registers itself' do
        RayoNode.class_from_registration(:accept, 'urn:xmpp:rayo:1').should be == Accept
      end

      it_should_behave_like 'command_headers'

      describe "from a stanza" do
        let(:stanza) { '<accept xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Accept }
      end
    end
  end
end # Punchblock
