# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Unmute do
      it 'registers itself' do
        RayoNode.class_from_registration(:unmute, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let(:stanza) { '<unmute xmlns="urn:xmpp:rayo:1"/>' }

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }
      end

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = RayoNode.from_xml subject.to_rayo
          new_instance.should be_instance_of described_class
        end

        it "should render to a parent node if supplied" do
          doc = Nokogiri::XML::Document.new
          parent = Nokogiri::XML::Node.new 'foo', doc
          doc.root = parent
          rayo_doc = subject.to_rayo(parent)
          rayo_doc.should == parent
        end
      end
    end
  end
end
