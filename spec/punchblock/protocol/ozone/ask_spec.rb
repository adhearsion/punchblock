require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Ask do
        it 'registers itself' do
          Command.class_from_registration(:ask, 'urn:xmpp:ozone:ask:1').should == Ask
        end

        describe "when setting options in initializer" do
          subject do
            Ask.new 'Please enter your postal code.', :choices        => '[5 DIGITS]',
                                                      :grammar        => 'application/grammar+custom',
                                                      :voice          => 'kate',
                                                      :url            => "http://it.doesnt.matter.does.it/?",
                                                      :bargein        => true,
                                                      :min_confidence => 0.3,
                                                      :mode           => :speech,
                                                      :recognizer     => 'en-US',
                                                      :terminator     => '#',
                                                      :timeout        => 12000
          end

          its(:prompt)          { should == Ask::Prompt.new(:voice => 'kate', :text => 'Please enter your postal code.', :url => "http://it.doesnt.matter.does.it/?") }
          its(:bargein)         { should == true }
          its(:min_confidence)  { should == 0.3 }
          its(:mode)            { should == :speech }
          its(:recognizer)      { should == 'en-US' }
          its(:terminator)      { should == '#' }
          its(:timeout)         { should == 12000 }
          its(:choices)         { should == Ask::Choices.new('[5 DIGITS]', 'application/grammar+custom') }
        end

        describe Ask::Choices do
          pending "Write some proper specs for me!"

          describe 'with a GRXML grammar' do
            subject { Ask::Choices.new grxml, 'application/grammar+grxml' }

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

        describe Ask::Complete::Success do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:ozone:ext:1'>
  <success mode="speech" confidence="0.45" xmlns='urn:xmpp:ozone:ask:complete:1'>
    <interpretation>1234</interpretation>
    <utterance>one two three four</utterance>
  </success>
</complete>
            MESSAGE
          end

          subject { Event.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::Success }

          its(:name)            { should == :success }
          its(:mode)            { should == :speech }
          its(:confidence)      { should == 0.45 }
          its(:interpretation)  { should == '1234' }
          its(:utterance)       { should == 'one two three four' }
        end

        describe Ask::Complete::NoMatch do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:ozone:ext:1'>
  <nomatch xmlns='urn:xmpp:ozone:ask:complete:1' />
</complete>
            MESSAGE
          end

          subject { Event.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::NoMatch }

          its(:name) { should == :nomatch }
        end

        describe Ask::Complete::NoInput do
          let :stanza do
            <<-MESSAGE
<complete xmlns='urn:xmpp:ozone:ext:1'>
  <noinput xmlns='urn:xmpp:ozone:ask:complete:1' />
</complete>
            MESSAGE
          end

          subject { Event.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Ask::Complete::NoInput }

          its(:name) { should == :noinput }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
