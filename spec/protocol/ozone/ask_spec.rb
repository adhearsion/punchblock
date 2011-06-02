require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Ask do
        subject { Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]' }

        let :expected_message do
          <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
</ask>
          MESSAGE
        end

        its(:to_xml) { should == expected_message.strip }

        describe "with an alternate grammar" do
          subject { Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]', :grammar => 'application/grammar+custom' }

          let :expected_message do
            <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
            MESSAGE
          end

          its(:to_xml) { should == expected_message.strip }
        end

        describe 'with a GRXML grammar' do
          subject { Ask.new 'Please enter your postal code.', :choices => grxml, :grammar => 'application/grammar+grxml' }

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

          let :expected_message do
            <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+grxml"><![CDATA[<grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE">
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
]]></choices>
</ask>
            MESSAGE
          end

          its(:to_xml) { should == expected_message.strip }
        end

        describe 'with alternate grammar, voice and attributes' do
          subject do
            Ask.new 'Please enter your postal code.', :choices        => '[5 DIGITS]',
                                                      :grammar        => 'application/grammar+custom',
                                                      :voice          => 'kate',
                                                      :bargein        => true,
                                                      :min_confidence => '0.3',
                                                      :mode           => :speech,
                                                      :recognizer     => 'en-US',
                                                      :terminator     => '#',
                                                      :timeout        => 12000
          end

          let :expected_message do
            <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1" bargein="true" min-confidence="0.3" mode="speech" recognizer="en-US" terminator="#" timeout="12000">
  <prompt voice="kate">Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
            MESSAGE
          end

          its(:to_xml) { should == expected_message.strip }
        end
      end
    end
  end
end
