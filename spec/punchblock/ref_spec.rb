# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Ref do
    it 'registers itself' do
      RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1').should be == described_class
    end

    describe "from a stanza" do
      let(:uri)     { 'some_uri' }
      let(:stanza)  { "<ref uri='#{uri}' xmlns='urn:xmpp:rayo:1' />" }

      subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

      it { should be_instance_of described_class }
      its(:target_call_id)  { should be == '9f00061' }

      context "when the URI isn't actually a URI" do
        let(:uri) { 'fgh4590' }

        its(:uri)           { should be == URI('fgh4590') }
        its(:scheme)        { should be == nil }
        its(:call_id)       { should be == 'fgh4590' }
        its(:domain)        { should be == nil }
        its(:component_id)  { should be == 'fgh4590' }
      end

      context "when the URI is an XMPP JID" do
        let(:uri) { 'xmpp:fgh4590@rayo.net/abc123' }

        its(:uri)           { should be == URI('xmpp:fgh4590@rayo.net/abc123') }
        its(:scheme)        { should be == 'xmpp' }
        its(:call_id)       { should be == 'fgh4590' }
        its(:domain)        { should be == 'rayo.net' }
        its(:component_id)  { should be == 'abc123' }
      end

      context "when the URI is an asterisk UUID" do
        let(:uri) { 'asterisk:fgh4590' }

        its(:uri)           { should be == URI('asterisk:fgh4590') }
        its(:scheme)        { should be == 'asterisk' }
        its(:call_id)       { should be == 'fgh4590' }
        its(:domain)        { should be == nil }
        its(:component_id)  { should be == 'fgh4590' }
      end
    end

    describe "when setting options in initializer" do
      subject { Ref.new uri: uri }
      let(:uri) { 'xmpp:fgh4590@rayo.net/abc123' }

      its(:uri) { should be == URI('xmpp:fgh4590@rayo.net/abc123') }

      describe "exporting to Rayo" do
        context "when the URI isn't actually a URI" do
          let(:uri) { 'fgh4590' }

          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.uri.should == URI('fgh4590')
          end
        end

        context "when the URI is an XMPP JID" do
          let(:uri) { 'xmpp:fgh4590@rayo.net' }

          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.uri.should == URI('xmpp:fgh4590@rayo.net')
          end
        end

        context "when the URI is an asterisk UUID" do
          let(:uri) { 'asterisk:fgh4590' }

          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.uri.should == URI('asterisk:fgh4590')
          end
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
