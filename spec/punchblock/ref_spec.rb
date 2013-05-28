# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Ref do
    it 'registers itself' do
      RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1').should be == described_class
    end

    describe "from a stanza" do
      let(:stanza) { "<ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />" }

      subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

      it { should be_instance_of described_class }

      it_should_behave_like 'event'

      its(:id) { should be == 'fgh4590' }
    end

    describe "when setting options in initializer" do
      subject { Ref.new :id => 'foo' }

      its(:id) { should be == 'foo' }

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = RayoNode.from_xml subject.to_rayo
          new_instance.should be_instance_of described_class
          new_instance.id.should == 'foo'
        end

        it "should render to a parent node if supplied" do
          doc = Nokogiri::XML::Document.new
          parent = Nokogiri::XML::Node.new 'foo', doc
          doc.root = parent
          rayo_doc = subject.to_rayo(parent)
          rayo_doc.should == parent
        end

        context "when attributes are not set" do
          subject { described_class.new }

          it "should not include them in the XML representation" do
            subject.to_rayo['id'].should be_nil
          end
        end
      end
    end
  end
end
