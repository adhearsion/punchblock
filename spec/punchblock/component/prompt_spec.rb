# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Prompt do
      it 'registers itself' do
        RayoNode.class_from_registration(:prompt, 'urn:xmpp:rayo:prompt:1').should be == described_class
      end

      describe "when setting options in initializer" do
        let(:output)  { Output.new :render_document => {content_type: 'text/uri-list', value: ['http://example.com/hello.mp3']} }
        let(:input)   { Input.new :mode => :speech }
        subject       { described_class.new output, input, :barge_in => true }

        its(:output)    { should be == output }
        its(:input)     { should be == input }
        its(:barge_in)  { should be_true }

        context "with barge-in unset" do
          subject { described_class.new output, input }

          its(:barge_in) { should be_nil }
        end

        context "with options for sub-components" do
          subject { described_class.new({renderer: :foo}, {recognizer: :bar}) }

          its(:output)  { should be == Output.new(renderer: :foo) }
          its(:input)   { should be == Input.new(recognizer: :bar) }
        end

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.output.should be == output
            new_instance.input.should be == input
            new_instance.barge_in.should be_true
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

      describe "from a stanza" do
        let :ssml do
          RubySpeech::SSML.draw do
            audio :src => 'http://foo.com/bar.mp3'
          end
        end

        let :stanza do
          <<-MESSAGE
<prompt xmlns="urn:xmpp:rayo:prompt:1" barge-in="true">
  <output xmlns="urn:xmpp:rayo:output:1" voice="allison">
    <document content-type="application/ssml+xml">
      <![CDATA[
        <speak version="1.0"
              xmlns="http://www.w3.org/2001/10/synthesis"
              xml:lang="en-US">
          <audio src="http://foo.com/bar.mp3"/>
        </speak>
      ]]>
    </document>
  </output>
  <input xmlns="urn:xmpp:rayo:input:1" mode="speech">
    <grammar content-type="application/grammar+custom">
      <![CDATA[ [5 DIGITS] ]]>
    </grammar>
  </input>
</prompt>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:barge_in)  { should be_true }
        its(:output)    { should be == Output.new(:voice => 'allison', :render_document => {:value => ssml}) }
        its(:input)     { should be == Input.new(:mode => :speech, :grammar => {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'}) }
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { described_class.new }

        before do
          command.component_id = 'abc123'
          command.target_call_id = '123abc'
          command.client = mock_client
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should be == '<stop xmlns="urn:xmpp:rayo:ext:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.should_receive(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Prompt that is new")
            end
          end
        end
      end
    end
  end
end # Punchblock
