# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Input do
      it 'registers itself' do
        RayoNode.class_from_registration(:input, 'urn:xmpp:rayo:input:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject do
          described_class.new grammar: {value: '[5 DIGITS]', content_type: 'application/grammar+custom'},
                    :mode                 => :voice,
                    :terminator           => '#',
                    :max_silence          => 1000,
                    :recognizer           => 'default',
                    :language             => 'en-US',
                    :initial_timeout      => 2000,
                    :inter_digit_timeout  => 2000,
                    :sensitivity          => 0.5,
                    :min_confidence       => 0.5
        end

        its(:grammars)            { should be == [Input::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom')] }
        its(:mode)                { should be == :voice }
        its(:terminator)          { should be == '#' }
        its(:max_silence)         { should be == 1000 }
        its(:recognizer)          { should be == 'default' }
        its(:language)            { should be == 'en-US' }
        its(:initial_timeout)     { should be == 2000 }
        its(:inter_digit_timeout) { should be == 2000 }
        its(:sensitivity)         { should be == 0.5 }
        its(:min_confidence)      { should be == 0.5 }

        context "with multiple grammars" do
          subject do
            Input.new :grammars => [
              {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'},
              {:value => '[10 DIGITS]', :content_type => 'application/grammar+custom'}
            ]
          end

          its(:grammars) { should be == [
            Input::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'),
            Input::Grammar.new(:value => '[10 DIGITS]', :content_type => 'application/grammar+custom')
          ]}
        end

        context "with a nil grammar" do
          it "removes all grammars" do
            subject.grammar = nil
            subject.grammars.should == []
          end
        end

        context "without any grammars" do
          subject { described_class.new }

          its(:grammars) { should == [] }
        end

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.grammars.should be == [Input::Grammar.new(value: '[5 DIGITS]', content_type: 'application/grammar+custom')]
            new_instance.mode.should be == :voice
            new_instance.terminator.should be == '#'
            new_instance.max_silence.should be == 1000
            new_instance.recognizer.should be == 'default'
            new_instance.language.should be == 'en-US'
            new_instance.initial_timeout.should be == 2000
            new_instance.inter_digit_timeout.should be == 2000
            new_instance.sensitivity.should be == 0.5
            new_instance.min_confidence.should be == 0.5
          end

          it "should wrap the grammar value in CDATA" do
            grammar_node = subject.to_rayo.at_xpath('ns:grammar', ns: described_class.registered_ns)
            grammar_node.children.first.should be_a Nokogiri::XML::CDATA
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
        let :stanza do
          <<-MESSAGE
<input xmlns="urn:xmpp:rayo:input:1"
       mode="voice"
       terminator="#"
       max-silence="1000"
       recognizer="default"
       language="en-US"
       initial-timeout="2000"
       inter-digit-timeout="2000"
       sensitivity="0.5"
       min-confidence="0.5">
  <grammar content-type="application/grammar+custom">
    <![CDATA[ [5 DIGITS] ]]>
  </grammar>
  <grammar content-type="application/grammar+custom">
    <![CDATA[ [10 DIGITS] ]]>
  </grammar>
</input>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Input }

        its(:grammars)            { should be == [Input::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'), Input::Grammar.new(:value => '[10 DIGITS]', :content_type => 'application/grammar+custom')] }
        its(:mode)                { should be == :voice }
        its(:terminator)          { should be == '#' }
        its(:max_silence)         { should be == 1000 }
        its(:recognizer)          { should be == 'default' }
        its(:language)            { should be == 'en-US' }
        its(:initial_timeout)     { should be == 2000 }
        its(:inter_digit_timeout) { should be == 2000 }
        its(:sensitivity)         { should be == 0.5 }
        its(:min_confidence)      { should be == 0.5 }

        context "without any grammars" do
          let(:stanza) { '<input xmlns="urn:xmpp:rayo:input:1"/>' }
          its(:grammars) { should be == [] }
        end
      end

      def grxml_doc(mode = :dtmf)
        RubySpeech::GRXML.draw :mode => mode.to_s, :root => 'digits' do
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
          its(:content_type) { should be == 'application/srgs+xml' }
        end

        describe 'with a GRXML grammar' do
          subject { Input::Grammar.new :value => grxml_doc, :content_type => 'application/srgs+xml' }

          its(:content_type) { should be == 'application/srgs+xml' }

          its(:value) { should be == grxml_doc }

          describe "comparison" do
            let(:grammar2) { Input::Grammar.new :value => grxml_doc }
            let(:grammar3) { Input::Grammar.new :value => grxml_doc(:voice) }

            it { should be == grammar2 }
            it { should_not be == grammar3 }
          end
        end

        describe 'with a grammar reference by URL' do
          let(:url) { 'http://foo.com/bar.grxml' }

          subject { Input::Grammar.new :url => url }

          its(:url)           { should be == url }
          its(:content_type)  { should be nil}

          describe "comparison" do
            it "should be the same with the same url" do
              Input::Grammar.new(:url => url).should be == Input::Grammar.new(:url => url)
            end

            it "should be different with a different url" do
              Input::Grammar.new(:url => url).should_not be == Input::Grammar.new(:url => 'http://doo.com/dah')
            end
          end
        end
      end

      describe "actions" do
        let(:mock_client) { double 'Client' }
        let(:command) { described_class.new grammar: {value: '[5 DIGITS]', content_type: 'application/grammar+custom'} }

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
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Input that is new")
            end
          end
        end
      end

      describe Input::Complete::Match do
        let :nlsml_string do
          '''
<result xmlns="http://www.ietf.org/xml/ns/mrcpv2" grammar="http://flight">
  <interpretation confidence="0.60">
    <input mode="voice">I want to go to Pittsburgh</input>
    <instance>
      <airline>
        <to_city>Pittsburgh</to_city>
      </airline>
    </instance>
  </interpretation>
  <interpretation confidence="0.40">
    <input>I want to go to Stockholm</input>
    <instance>
      <airline>
        <to_city>Stockholm</to_city>
      </airline>
    </instance>
  </interpretation>
</result>
          '''
        end

        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    <![CDATA[#{nlsml_string}]]>
  </match>
</complete>
          MESSAGE
        end

        let :expected_nlsml do
          RubySpeech.parse nlsml_string
        end

        subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::Match }

        its(:name)            { should be == :match }
        its(:content_type)    { should be == 'application/nlsml+xml' }
        its(:nlsml)           { should be == expected_nlsml }
        its(:mode)            { should be == :voice }
        its(:confidence)      { should be == 0.6 }
        its(:interpretation)  { should be == { airline: { to_city: 'Pittsburgh' } } }
        its(:utterance)       { should be == 'I want to go to Pittsburgh' }

        describe "when creating from an NLSML document" do
          subject do
            Input::Complete::Match.new :nlsml => expected_nlsml
          end

          its(:content_type)    { should be == 'application/nlsml+xml' }
          its(:nlsml)           { should be == expected_nlsml }
          its(:mode)            { should be == :voice }
          its(:confidence)      { should be == 0.6 }
          its(:interpretation)  { should be == { airline: { to_city: 'Pittsburgh' } } }
          its(:utterance)       { should be == 'I want to go to Pittsburgh' }
        end

        context "when not enclosed in CDATA, but escaped" do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    &lt;result xmlns=&quot;http://www.ietf.org/xml/ns/mrcpv2&quot; grammar=&quot;http://flight&quot;/&gt;
  </match>
</complete>
            MESSAGE
          end

          it "should parse the NLSML correctly" do
            subject.nlsml.grammar.should == "http://flight"
          end
        end

        context "when nested directly" do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    #{nlsml_string}
  </match>
</complete>
            MESSAGE
          end

          it "should parse the NLSML correctly" do
            subject.nlsml.grammar.should == "http://flight"
          end
        end

        describe "comparison" do
          context "with the same nlsml" do
            it "should be equal" do
              subject.should == RayoNode.from_xml(parse_stanza(stanza).root).reason
            end
          end

          context "with different nlsml" do
            let :other_stanza do
              <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1">
    <![CDATA[<result xmlns="http://www.ietf.org/xml/ns/mrcpv2" grammar="http://flight"/>]]>
  </match>
</complete>
              MESSAGE
            end

            it "should not be equal" do
              subject.should_not == RayoNode.from_xml(parse_stanza(other_stanza).root).reason
            end
          end
        end
      end

      describe Input::Complete::NoMatch do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <nomatch xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::NoMatch }

        its(:name) { should be == :nomatch }
      end

      describe Input::Complete::NoInput do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <noinput xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

        it { should be_instance_of Input::Complete::NoInput }

        its(:name) { should be == :noinput }
      end
    end
  end
end # Punchblock
