# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Unjoin do

      it 'registers itself' do
        RayoNode.class_from_registration(:unjoin, 'urn:xmpp:rayo:1').should be == Unjoin
      end

      describe "when setting options in initializer" do
        subject { Unjoin.new :call_id => 'abc123', :mixer_name => 'blah' }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<unjoin xmlns="urn:xmpp:rayo:1"
      call-id="abc123"
      mixer-name="blah" />
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Unjoin }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
      end
    end
  end
end # Punchblock
