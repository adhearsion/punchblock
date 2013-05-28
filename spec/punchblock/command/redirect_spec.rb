# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Redirect do
      it 'registers itself' do
        RayoNode.class_from_registration(:redirect, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject { described_class.new to: 'tel:+14045551234', headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        its(:to) { should be == 'tel:+14045551234' }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.to.should == 'tel:+14045551234'
            new_instance.headers.should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
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
              subject.to_rayo['to'].should be_nil
            end
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<redirect xmlns='urn:xmpp:rayo:1'
    to='tel:+14045551234'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</redirect>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:to) { should be == 'tel:+14045551234' }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers or to provided" do
          let(:stanza) { '<redirect xmlns="urn:xmpp:rayo:1"/>' }

          its(:to) { should be_nil }
          its(:headers) { should == {} }
        end
      end
    end # Redirect
  end # Command
end # Punchblock
