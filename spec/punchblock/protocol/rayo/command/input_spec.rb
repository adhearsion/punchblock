require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
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
            its(:recognizer)          { should == 'en-US' }
            its(:initial_timeout)     { should == 2000 }
            its(:inter_digit_timeout) { should == 2000 }
            its(:term_timeout)        { should == 2000 }
            its(:complete_timeout)    { should == 2000 }
            its(:incomplete_timeout)  { should == 2000 }
            its(:sensitivity)         { should == 0.5 }
            its(:min_confidence)      { should == 0.5 }
          end

          describe Input::Grammar do
            describe "when not passing a grammar" do
              subject { Input::Grammar.new :value => '[5 DIGITS]' }
              its(:content_type) { should == 'application/grammar+voxeo' }
            end

            describe 'with a GRXML grammar' do
              subject { Input::Grammar.new :value => grxml, :content_type => 'application/grammar+grxml' }

              let :grxml do
                <<-GRXML
  <grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE">
    <rule id="MAINRULE">
      <one-of>
        <item>
          <item repeat="0-1"> need a</item>
          <item repeat="0-1"> i need a</item>
            <one-of>
              <item> clue </item>
            </one-of>
          <tag> out.concept = "clue";</tag>
        </item>
        <item>
          <item repeat="0-1"> have an</item>
          <item repeat="0-1"> i have an</item>
            <one-of>
              <item> answer </item>
            </one-of>
          <tag> out.concept = "answer";</tag>
        </item>
      </one-of>
    </rule>
  </grammar>
                GRXML
              end

              let(:expected_message) { "<![CDATA[#{grxml}]]>" }

              it "should wrap GRXML in CDATA" do
                subject.child.to_xml.should == expected_message.strip
              end
            end
          end

          describe "actions" do
            let(:command) { Input.new :grammar => '[5 DIGITS]' }

            before do
              command.command_id = 'abc123'
              command.call_id = '123abc'
              command.connection = Connection.new :username => '123', :password => '123'
            end

            describe '#stop_action' do
              subject { command.stop_action }

              its(:to_xml) { should == '<stop xmlns="urn:xmpp:rayo:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#stop!' do
              describe "when the command is executing" do
                before do
                  command.request!
                  command.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', command.stop_action, 'abc123')
                  command.stop!
                end
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop an Input that is not executing.")
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
    end # Rayo
  end # Protocol
end # Punchblock
