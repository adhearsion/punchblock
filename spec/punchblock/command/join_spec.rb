# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Join do
      it 'registers itself' do
        RayoNode.class_from_registration(:join, 'urn:xmpp:rayo:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject { described_class.new :call_uri => 'abc123', :mixer_name => 'blah', :direction => :duplex, :media => :bridge }

        its(:call_uri)    { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
        its(:direction)   { should be == :duplex }
        its(:media)       { should be == :bridge }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.call_uri.should == 'abc123'
            new_instance.mixer_name.should == 'blah'
            new_instance.direction.should == :duplex
            new_instance.media.should == :bridge
          end

          it "should render to a parent node if supplied" do
            doc = Nokogiri::XML::Document.new
            parent = Nokogiri::XML::Node.new 'foo', doc
            doc.root = parent
            rayo_doc = subject.to_rayo(parent)
            rayo_doc.should == parent
          end

          context "when attributes are not set" do
            subject { described_class.new call_uri: 'abc123' }

            it "should not include them in the XML representation" do
              subject.to_rayo['call-uri'].should == 'abc123'
              subject.to_rayo['mixer-name'].should be_nil
            end
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<join xmlns="urn:xmpp:rayo:1"
      call-uri="abc123"
      mixer-name="blah"
      direction="duplex"
      media="bridge" />
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:call_uri)    { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
        its(:direction)   { should be == :duplex }
        its(:media)       { should be == :bridge }

        context "when no attributes are set" do
          let(:stanza) { '<join xmlns="urn:xmpp:rayo:1" />' }

          its(:call_uri)    { should be_nil }
          its(:mixer_name)  { should be_nil }
          its(:direction)   { should be_nil }
          its(:media)       { should be_nil }
        end
      end

      describe "with a direction" do
        [nil, :duplex, :send, :recv].each do |direction|
          describe direction do
            subject { described_class.new :direction => direction }

            its(:direction) { should be == direction }
          end
        end

        describe "no direction" do
          subject { described_class.new }

          its(:direction) { should be_nil }
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { described_class.new(:direction => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end
  end
end # Punchblock
