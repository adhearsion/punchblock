require 'spec_helper'

describe 'Ozone message generator' do
  before :all do
    @module = Punchblock::Protocol::Ozone
  end

  describe "should create a correct" do
    it '"accept" message' do
      @module::Message::Accept.new.to_xml.should == '<accept xmlns="urn:xmpp:ozone:1"/>'
    end

    it '"answer" message' do
      @module::Message::Answer.new.to_xml.should == '<answer xmlns="urn:xmpp:ozone:1"/>'
    end

    it '"hangup" message' do
      @module::Message::Hangup.new.to_xml.should == '<hangup xmlns="urn:xmpp:ozone:1"/>'
    end

    it '"reject" message with the default reason' do
      expected_response = <<-RESPONSE
<reject xmlns="urn:xmpp:ozone:1">
  <declined/>
</reject>
      RESPONSE
      @module::Message::Reject.new.to_xml.should == expected_response.chomp
    end

    it '"reject" message with a specified reason' do
      expected_response = <<-RESPONSE
<reject xmlns="urn:xmpp:ozone:1">
  <busy/>
</reject>
      RESPONSE
      @module::Message::Reject.new(:busy).to_xml.should == expected_response.chomp
    end

    it 'ArgumentError exception for a reject with an invalid reason' do
      expect {
        @module::Message::Reject.new(:blahblahblah)
      }.to raise_error ArgumentError
    end

    it '"redirect" message' do
      @module::Message::Redirect.new('tel:+14045551234').to_xml.should == '<redirect xmlns="urn:xmpp:ozone:1" to="tel:+14045551234"/>'
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
        expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
</ask>
        RESPONSE
        msg = @module::Message::Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]'
        msg.to_xml.should == expected_response.chomp
      end

      it '"ask" message with an alternate grammar' do
        expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
        RESPONSE
        msg = @module::Message::Ask.new 'Please enter your postal code.', { :choices => '[5 DIGITS]', 
                                                                            :grammar => 'application/grammar+custom' }
        msg.to_xml.should == expected_response.chomp
      end
    
      it '"ask" message with a GRXML grammar' do
        expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+grxml"><grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE"><rule id="MAINRULE"><one-of><item><item repeat="0-1"> need a</item><item repeat="0-1"> i need a</item><one-of><item> clue </item></one-of><tag> out.concept = "clue";</tag></item><item><item repeat="0-1"> have an</item><item repeat="0-1"> i have an</item><one-of><item> answer </item></one-of><tag> out.concept = "answer";</tag></item></one-of></rule></grammar>
</choices>
</ask>
RESPONSE
        
        msg = @module::Message::Ask.new 'Please enter your postal code.', { :choices => @grxml, 
                                                                            :grammar => 'application/grammar+grxml' }
        msg.to_xml.should == expected_response.chomp
      end
    
      it '"ask"message with alternate grammar, voice and attributes' do
        expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1" mode="speech|dtmf|both" bargein="true" min-confidence="0.3" recognizer="en-US" terminator="#" timeout="12000">
  <prompt>Please enter your postal code.</prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
        RESPONSE
        msg = @module::Message::Ask.new 'Please enter your postal code.', { :choices        => '[5 DIGITS]',
                                                                            :grammar        => 'application/grammar+custom',
                                                                            :voice          => 'kate',
                                                                            :bargein        => true,
                                                                            :min_confidence => '0.3',
                                                                            :mode           => 'speech|dtmf|both',
                                                                            :recognizer     => 'en-US',
                                                                            :terminator     => '#',
                                                                            :timeout        => 12000 }
        msg.to_xml.should eql expected_response.chomp
      end
    end
    
    it '"conference" message' do
      msg = @module::Message::Conference.new('1234')
      msg.to_xml.should == '<conference xmlns="urn:xmpp:ozone:conference:1" name="1234"/>'
    end

    it '"conference" message with options' do
      expected_response = <<-RESPONSE
<conference xmlns="urn:xmpp:ozone:conference:1" tone-passthrough="true" mute="false" beep="true" terminator="#" name="1234" moderator="true">
  <music>
    <speak>Welcome to Ozone</speak>
    <audio url="http://it.doesnt.matter.does.it/?"/>
  </music>
</conference>
      RESPONSE
      msg = @module::Message::Conference.new '1234',{ :beep             => true, 
                                                      :terminator       => '#', 
                                                      :prompt           => "Welcome to Ozone", 
                                                      :audio_url        => "http://it.doesnt.matter.does.it/?",
                                                      :moderator        => true,
                                                      :tone_passthrough => true,
                                                      :mute             => false }
      msg.to_xml.should == expected_response.chomp
    end
    
    it '"dial" message' do
      msg = @module::Message::Dial.new(:to => 'tel:+14155551212', :from => '+13035551212')
      msg.to_xml.should == '<dial xmlns="urn:xmpp:ozone:dial:1" to="tel:+14155551212" from="+13035551212"/>'.chomp
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
        expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1">
  <audio src="http://whatever.you-say-boss.com"/>
</say>
        RESPONSE
        @module::Message::Say.new(:url => 'http://whatever.you-say-boss.com').to_xml.should == expected_response.chomp
      end

      it '"say" message for text' do
        expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1" voice="kate">Once upon a time there was a message...</say>
        RESPONSE
        msg = @module::Message::Say.new(:text => 'Once upon a time there was a message...', :voice => 'kate')
        msg.to_xml.should == expected_response.chomp
      end
      
      it '"say" message for SSML' do
        expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1">
  <say-as interpret-as="ordinal">100</say-as>
</say>
        RESPONSE
        msg = @module::Message::Say.new(:ssml => '<say-as interpret-as="ordinal">100</say-as>')
        msg.to_xml.should == expected_response.chomp
      end
    
    it '"say" message for SSML with a custom voice' do
      expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1" voice="kate">
  <say-as interpret-as="ordinal">100</say-as>
</say>
      RESPONSE
      msg = @module::Message::Say.new(:ssml => '<say-as interpret-as="ordinal">100</say-as>', :voice => 'kate')
      msg.to_xml.should == expected_response.chomp
    end
  end
        
    it '"transfer" message' do
      expected_response = <<-RESPONSE
<transfer xmlns="urn:xmpp:ozone:transfer:1" to="tel:+14045551212" terminator="*" from="tel:+14155551212" timeout="120000" answer-on-media="true"/>
      RESPONSE
      msg = @module::Message::Transfer.new('tel:+14045551212', { :from            => 'tel:+14155551212',
                                                                 :terminator      => '*',
                                                                 :timeout         => 120000,
                                                                 :answer_on_media => 'true' })
      msg.to_xml.should eql expected_response.chomp
    end

    it '"transfer" message with options' do
      expected_response = '<transfer xmlns="urn:xmpp:ozone:transfer:1" to="tel:+14045551212" terminator="#"/>'
      msg = @module::Message::Transfer.new('tel:+14045551212', :terminator => "#")
      msg.to_xml.should == expected_response.chomp
    end
  end
end
