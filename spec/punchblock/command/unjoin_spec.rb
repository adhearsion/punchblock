# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Unjoin do
      it 'registers itself' do
        RayoNode.class_from_registration(:unjoin, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject { Unjoin.new :call_id => 'abc123', :mixer_name => 'blah' }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.call_id.should == 'abc123'
            new_instance.mixer_name.should == 'blah'
          end

          it "should render to a parent node if supplied" do
            doc = Nokogiri::XML::Document.new
            parent = Nokogiri::XML::Node.new 'foo', doc
            doc.root = parent
            rayo_doc = subject.to_rayo(parent)
            rayo_doc.should == parent
          end

          context "when attributes are not set" do
            subject { described_class.new call_id: 'abc123' }

            it "should not include them in the XML representation" do
              subject.to_rayo['call-id'].should == 'abc123'
              subject.to_rayo['mixer-name'].should be_nil
            end
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<unjoin xmlns="urn:xmpp:rayo:1"
      call-id="abc123"
      mixer-name="blah" />
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
      end
    end
  end
end
