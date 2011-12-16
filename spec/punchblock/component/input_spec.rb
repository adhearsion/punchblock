require 'spec_helper'

module Punchblock
  module Component
    describe Input do
      it 'registers itself' do
        RayoNode.class_from_registration(:input, 'urn:xmpp:rayo:input:1').should == Input
      end

      describe "when setting options in initializer" do
        subject do
          Input.new :grammar              => {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'},
                    :mode                 => :speech,
                    :terminator           => '#',
                    :max_digits           => 10,
                    :max_silence          => 1000,
                    :recognizer           => 'en-US',
                    :initial_timeout      => 2000,
                    :inter_digit_timeout  => 2000,
                    :term_timeout         => 2000,
                    :complete_timeout     => 2000,
                    :incomplete_timeout   => 2000,
                    :sensitivity          => 0.5,
                    :min_confidence       => 0.5
        end

        its(:grammar)             { should == Input::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom') }
        its(:mode)                { should == :speech }
        its(:terminator)          { should == '#' }
        its(:max_digits)          { should == 10 }
        its(:max_silence)         { should == 1000 }
        its(:recognizer)          { should == 'en-US' }
        its(:initial_timeout)     { should == 2000 }
        its(:inter_digit_timeout) { should == 2000 }
        its(:term_timeout)        { should == 2000 }
        its(:complete_timeout)    { should == 2000 }
        its(:incomplete_timeout)  { should == 2000 }
        its(:sensitivity)         { should == 0.5 }
        its(:min_confidence)      { should == 0.5 }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<input xmlns="urn:xmpp:rayo:input:1"
       mode="speech"
       terminator="#"
       max-digits="10"
       max-silence="1000"
       recognizer="en-US"
       initial-timeout="2000"
       inter-digit-timeout="2000"
       term-timeout="2000"
       complete-timeout="2000"
       incomplete-timeout="2000"
       sensitivity="0.5"
       min-confidence="0.5">
  <grammar content-type="application/grammar+custom">
    <![CDATA[ [5 DIGITS] ]]>
  </grammar>
</input>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Input }

        its(:grammar)             { should == Input::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom') }
        its(:mode)                { should == :speech }
        its(:terminator)          { should == '#' }
        its(:max_digits)          { should == 10 }
        its(:max_silence)         { should == 1000 }
        its(:recognizer)          { should == 'en-US' }
        its(:initial_timeout)     { should == 2000 }
        its(:inter_digit_timeout) { should == 2000 }
        its(:term_timeout)        { should == 2000 }
        its(:complete_timeout)    { should == 2000 }
        its(:incomplete_timeout)  { should == 2000 }
        its(:sensitivity)         { should == 0.5 }
        its(:min_confidence)      { should == 0.5 }
      end

      def grxml_doc(mode = :dtmf)
        RubySpeech::GRXML.draw do
          self.mode = mode.to_s
          self.root = 'digits'

          rule id: 'digits' do
            one_of do
              0.upto(1) { |d| item { d.to_s } }
            end
          end
        end
      end

      describe Input::Grammar do
        describe "when not passing a content type" do
          subject { Input::Grammar.new :value => grxml_doc }
          its(:content_type) { should == 'application/grammar+grxml' }
        end

        describe 'with a simple grammar' do
          subject { Input::Grammar.new :value => '[5 DIGITS]', :content_type => 'application/grammar+custom' }

          let(:expected_message) { "<![CDATA[ [5 DIGITS] ]]>" }

          it "should wrap grammar in CDATA" do
            subject.child.to_xml.should == expected_message.strip
          end
        end

        describe 'with a GRXML grammar' do
          subject { Input::Grammar.new :value => grxml_doc, :content_type => 'application/grammar+grxml' }

          its(:content_type) { should == 'application/grammar+grxml' }

          let(:expected_message) { "<![CDATA[ #{grxml_doc} ]]>" }

          it "should wrap GRXML in CDATA" do
            subject.child.to_xml.should == expected_message.strip
          end

          its(:value) { should == grxml_doc }

          describe "comparison" do
            let(:grammar2) { Input::Grammar.new :value => '<grammar xmlns="http://www.w3.org/2001/06/grammar" version="1.0" xml:lang="en-US" mode="dtmf" root="digits"><rule id="digits"><one-of><item>0</item><item>1</item></one-of></rule></grammar>' }
            let(:grammar3) { Input::Grammar.new :value => grxml_doc }
            let(:grammar4) { Input::Grammar.new :value => grxml_doc(:speech) }

            it { should == grammar2 }
            it { should == grammar3 }
            it { should_not == grammar4 }
          end
        end
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { Input.new :grammar => '[5 DIGITS]' }

        before do
          command.component_id = 'abc123'
          command.call_id = '123abc'
          command.client = mock_client
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should == '<stop xmlns="urn:xmpp:rayo:1"/>' }
          its(:component_id) { should == 'abc123' }
          its(:call_id) { should == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.stop_action, :call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Input that is not executing")
            end
          end
        end
      end

      describe Input::Complete::Success do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<success mode="speech" confidence="0.45" xmlns='urn:xmpp:rayo:input:complete:1'>
  <interpretation>1234</interpretation>
  <utterance>one two three four</utterance>
</success>
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::Success }

        its(:name)            { should == :success }
        its(:mode)            { should == :speech }
        its(:confidence)      { should == 0.45 }
        its(:interpretation)  { should == '1234' }
        its(:utterance)       { should == 'one two three four' }
      end

      describe Input::Complete::NoMatch do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<nomatch xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::NoMatch }

        its(:name) { should == :nomatch }
      end

      describe Input::Complete::NoInput do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<noinput xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::NoInput }

        its(:name) { should == :noinput }
      end
    end
  end
end # Punchblock
