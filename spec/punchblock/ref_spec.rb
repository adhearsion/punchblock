# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Ref do
    it 'registers itself' do
      RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1').should be == Ref
    end

    describe "from a stanza" do
      let(:stanza) { "<ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />" }

      subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

      it { should be_instance_of Ref }

      it_should_behave_like 'event'

      its(:id) { should be == 'fgh4590' }
    end

    describe "when setting options in initializer" do
      subject { Ref.new :id => 'foo' }

      its(:id) { should be == 'foo' }
    end
  end
end # Punchblock
