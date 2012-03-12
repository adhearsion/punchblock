# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Hangup do
      it 'registers itself' do
        RayoNode.class_from_registration(:hangup, 'urn:xmpp:rayo:1').should == Hangup
      end

      it_should_behave_like 'command_headers'

      describe "from a stanza" do
        let(:stanza) { '<hangup xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Hangup }
      end
    end
  end
end # Punchblock
