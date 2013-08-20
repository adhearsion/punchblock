# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Ref do
    it 'registers itself' do
      RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1').should be == described_class
    end

    describe "from a stanza" do
      let(:stanza) { "<ref uri='xmpp:fgh4590@rayo.net' xmlns='urn:xmpp:rayo:1' />" }

      subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

      it { should be_instance_of described_class }

      it_should_behave_like 'event'

      its(:uri) { should be == RubyJID.new('fgh4590@rayo.net') }
    end

    describe "when setting options in initializer" do
      subject { Ref.new uri: 'xmpp:foo@bar.com' }

      its(:uri) { should be == RubyJID.new('foo@bar.com') }

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = RayoNode.from_xml subject.to_rayo
          new_instance.should be_instance_of described_class
          new_instance.uri.should == RubyJID.new('foo@bar.com')
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
            subject.to_rayo['uri'].should be_nil
          end
        end
      end
    end
  end
end
