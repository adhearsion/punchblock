# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Reject do
      it 'registers itself' do
        RayoNode.class_from_registration(:reject, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject { described_class.new reason: :busy, headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        its(:reason) { should be == :busy }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.reason.should == :busy
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
              subject.to_rayo.children.count.should == 0
            end
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<reject xmlns='urn:xmpp:rayo:1'>
  <busy />
  <!-- Sample Headers (optional) -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</reject>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:reason) { should be == :busy }
        its(:headers) { should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers or reason provided" do
          let(:stanza) { '<reject xmlns="urn:xmpp:rayo:1"/>' }

          its(:reason) { should be_nil }
          its(:headers) { should == {} }
        end
      end

      describe "with the reason" do
        [nil, :decline, :busy, :error].each do |reason|
          describe reason do
            subject { described_class.new :reason => reason }

            its(:reason) { should be == reason }
          end
        end

        describe "no reason" do
          subject { described_class.new }

          its(:reason) { should be_nil }
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { described_class.new(:reason => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end
  end
end # Punchblock
