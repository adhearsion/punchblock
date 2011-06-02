require 'spec_helper'

describe 'Ozone message generator' do
  before :all do
    @module = Punchblock::Protocol::Ozone
  end

  describe "should create a correct" do
    it '"accept" message' do
      @module::Accept.new.to_xml.should == '<accept xmlns="urn:xmpp:ozone:1"/>'
    end

    it '"answer" message' do
      @module::Answer.new.to_xml.should == '<answer xmlns="urn:xmpp:ozone:1"/>'
    end

    it '"hangup" message' do
      @module::Hangup.new.to_xml.should == '<hangup xmlns="urn:xmpp:ozone:1"/>'
    end

    describe 'reject' do
      it '"reject" message with the default reason' do
        expected_message = <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <declined/>
</reject>
        MESSAGE
        @module::Reject.new.to_xml.should == expected_message.chomp
      end

      it '"reject" message with the declined reason' do
        expected_message = <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <declined/>
</reject>
        MESSAGE
        @module::Reject.new(:declined).to_xml.should == expected_message.chomp
      end

      it '"reject" message with a busy reason' do
        expected_message = <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <busy/>
</reject>
      MESSAGE
        @module::Reject.new(:busy).to_xml.should == expected_message.chomp
      end

      it '"reject" message with an error reason' do
        expected_message = <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <error/>
</reject>
      MESSAGE
        @module::Reject.new(:error).to_xml.should == expected_message.chomp
      end
    end

    it 'ArgumentError exception for a reject with an invalid reason' do
      expect {
        @module::Reject.new(:blahblahblah)
      }.to raise_error ArgumentError
    end

    it '"redirect" message' do
      @module::Redirect.new('tel:+14045551234').to_xml.should == '<redirect xmlns="urn:xmpp:ozone:1" to="tel:+14045551234"/>'
    end

    describe 'ask' do
      before(:all) do
        @grxml = <<-GRXML
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

      it '"ask" message' do
        expected_message = <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
</ask>
        MESSAGE
        msg = @module::Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]'
        msg.to_xml.should == expected_message.chomp
      end

      it '"ask" message with an alternate grammar' do
        expected_message = <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
        MESSAGE
        msg = @module::Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]', :grammar => 'application/grammar+custom'
        msg.to_xml.should == expected_message.chomp
      end

      it '"ask" message with a GRXML grammar' do
        expected_message = <<-MESSAGE
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

        msg = @module::Ask.new 'Please enter your postal code.', :choices => @grxml, :grammar => 'application/grammar+grxml'
        msg.to_xml.should == expected_message.strip
      end

      it '"ask" message with alternate grammar, voice and attributes' do
        expected_message = <<-MESSAGE
<ask xmlns="urn:xmpp:ozone:ask:1" bargein="true" min-confidence="0.3" mode="speech" recognizer="en-US" terminator="#" timeout="12000">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
        MESSAGE
        msg = @module::Ask.new 'Please enter your postal code.', :choices        => '[5 DIGITS]',
                                                                 :grammar        => 'application/grammar+custom',
                                                                 :voice          => 'kate',
                                                                 :bargein        => true,
                                                                 :min_confidence => '0.3',
                                                                 :mode           => :speech,
                                                                 :recognizer     => 'en-US',
                                                                 :terminator     => '#',
                                                                 :timeout        => 12000
        msg.to_xml.should == expected_message.strip
      end
    end

    it '"conference" message' do
      msg = @module::Conference.new '1234'
      msg.to_xml.should == '<conference xmlns="urn:xmpp:ozone:conference:1" name="1234"/>'
    end

    it '"conference" message with options' do
      expected_message = <<-MESSAGE
<conference xmlns="urn:xmpp:ozone:conference:1" beep="true" terminator="#" moderator="true" tone-passthrough="true" mute="false" name="1234">
  <music>
    <speak>Welcome to Ozone</speak>
    <audio url="http://it.doesnt.matter.does.it/?"/>
  </music>
</conference>
      MESSAGE

      msg = @module::Conference.new '1234', :beep             => true,
                                            :terminator       => '#',
                                            :prompt           => "Welcome to Ozone",
                                            :audio_url        => "http://it.doesnt.matter.does.it/?",
                                            :moderator        => true,
                                            :tone_passthrough => true,
                                            :mute             => false
      msg.to_xml.should == expected_message.strip

    end

    it '"dial" message' do
      msg = @module::Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212'
      msg.to_xml.should == '<dial xmlns="urn:xmpp:ozone:1" to="tel:+14155551212" from="tel:+13035551212"/>'
    end

    it '"pause" message' do
      pending 'Need to construct the parent object first'
      pause.to_xml.should == '<pause xmlns="urn:xmpp:ozone:say:1"/>'
    end

    it '"resume" message' do
      pending 'Need to construct the parent object first'
      resume(:say).to_xml.should == '<resume xmlns="urn:xmpp:ozone:say:1"/>'
    end

    it '"mute" message' do
      pending 'Need to construct the parent object first'
      mute.to_xml.should == '<mute xmlns="urn:xmpp:ozone:conference:1"/>'
    end

    it '"unmute" message' do
      pending 'Need to construct the parent object first'
      unmute.to_xml.should == '<unmute xmlns="urn:xmpp:ozone:conference:1"/>'
    end

    it '"kick" message' do
      pending 'Need to construct the parent object first'
      kick.to_xml.should == '<kick xmlns="urn:xmpp:ozone:conference:1"/>'
    end

    it '"stop" message' do
      pending 'Need to construct the parent object first'
      stop(:say).to_xml.should == '<stop xmlns="urn:xmpp:ozone:say:1"/>'
    end

    describe 'say' do
      it '"say" message for audio' do
        expected_message = <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1">
  <audio src="http://whatever.you-say-boss.com"/>
</say>
        MESSAGE
        @module::Say.new(:url => 'http://whatever.you-say-boss.com').to_xml.should == expected_message.chomp
      end

      it '"say" message for text' do
        expected_message = <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1" voice="kate">Once upon a time there was a message...</say>
        MESSAGE
        msg = @module::Say.new :text => 'Once upon a time there was a message...', :voice => 'kate'
        msg.to_xml.should == expected_message.chomp
      end

      it '"say" message for SSML' do
        expected_message = <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1">
  <say-as interpret-as="ordinal">100</say-as>
</say>
        MESSAGE
        msg = @module::Say.new :ssml => '<say-as interpret-as="ordinal">100</say-as>'
        msg.to_xml.should == expected_message.chomp
      end

    it '"say" message for SSML with a custom voice' do
      expected_message = <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1" voice="kate">
  <say-as interpret-as="ordinal">100</say-as>
</say>
      MESSAGE
      msg = @module::Say.new :ssml => '<say-as interpret-as="ordinal">100</say-as>', :voice => 'kate'
      msg.to_xml.should == expected_message.chomp
    end
  end

    it '"transfer" message' do
      expected_message = '<transfer xmlns="urn:xmpp:ozone:transfer:1" from="tel:+14155551212" terminator="*" timeout="120000" answer-on-media="true" to="tel:+14045551212"/>'
      msg = @module::Transfer.new 'tel:+14045551212', :from            => 'tel:+14155551212',
                                                      :terminator      => '*',
                                                      :timeout         => 120000,
                                                      :answer_on_media => 'true'
      msg.to_xml.should == expected_message
    end
  end
end
