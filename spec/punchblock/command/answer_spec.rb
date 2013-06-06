# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Answer do
      it 'registers itself' do
        RayoNode.class_from_registration(:answer, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "from a stanza" do
        let(:stanza) do
          <<-STANZA
            <answer xmlns="urn:xmpp:rayo:1">
              <header name="X-skill" value="agent" />
              <header name="X-customer-id" value="8877" />
            </answer>
          STANZA
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers provided" do
          let(:stanza) { '<answer xmlns="urn:xmpp:rayo:1"/>' }

          its(:headers) { should == {} }
        end
      end

      describe "when setting options in initializer" do
        subject { described_class.new headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.headers.should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
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
end
