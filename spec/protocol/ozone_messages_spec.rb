require 'spec_helper'

describe 'Ozone message generator' do
  include Punchblock::Protocol::Ozone

  it 'should generate a correct "answer" message' do
    Message::Answer.new.to_xml.should == '<answer xmlns="urn:xmpp:ozone:1"/>'
  end

  it 'should generate a correct "ask" message' do
    expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>
    <speak>Please enter your postal code.</speak>
  </prompt>
  <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
</ask>
    RESPONSE
    msg = Message::Ask.new 'Please enter your postal code.', '[5 DIGITS]'
    msg.to_xml.should == expected_response.chomp
  end

  it 'should generate a correct "ask" message with an alternate grammar' do
    expected_response = <<-RESPONSE
<ask xmlns="urn:xmpp:ozone:ask:1">
  <prompt>
    <speak>Please enter your postal code.</speak>
  </prompt>
  <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
</ask>
    RESPONSE
    msg = Message::Ask.new 'Please enter your postal code.', '[5 DIGITS]', :grammar => 'application/grammar+custom'
    msg.to_xml.should == expected_response.chomp
  end

  it 'should generate a correct "conference" message' do
    Message::Conference.new('1234').to_xml.should == '<conference xmlns="urn:xmpp:ozone:conference:1" id="1234"/>' 
  end

  it 'should generate a correct "conference" message with options' do
    expected_response = <<-RESPONSE
<conference xmlns="urn:xmpp:ozone:conference:1" id="1234" beep="true" terminator="#">
  <music>
    <speak>Welcome to Ozone</speak>
    <audio url="http://it.doesnt.matter.does.it/?"/>
  </music>
</conference>
    RESPONSE
    msg = Message::Conference.new '1234', :beep => true, :terminator => '#', :prompt => "Welcome to Ozone", :audio_url => "http://it.doesnt.matter.does.it/?"
    msg.to_xml.should == expected_response.chomp
  end

  it 'should create a correct "hangup" message' do
    Message::Hangup.new.to_xml.should == '<hangup xmlns="urn:xmpp:ozone:1"/>'
  end

  it 'should create a correct "pause" message' do
    pending 'Need to construct the parent object first'
    pause.to_xml.should == '<pause xmlns="urn:xmpp:ozone:say:1"/>'
  end

  it 'should create a correct "resume" message' do
    pending 'Need to construct the parent object first'
    resume(:say).to_xml.should == '<resume xmlns="urn:xmpp:ozone:say:1"/>'
  end

  it 'should create a correct "mute" message' do
    pending 'Need to construct the parent object first'
    mute.to_xml.should == '<mute xmlns="urn:xmpp:ozone:conference:1"/>'
  end

  it 'should create a correct "unmute" message' do
    pending 'Need to construct the parent object first'
    unmute.to_xml.should == '<unmute xmlns="urn:xmpp:ozone:conference:1"/>'
  end

  it 'should create a correct "kick" message' do
    pending 'Need to construct the parent object first'
    kick.to_xml.should == '<kick xmlns="urn:xmpp:ozone:conference:1"/>'
  end

  it 'should create a correct "stop" message' do
    pending 'Need to construct the parent object first'
    stop(:say).to_xml.should == '<stop xmlns="urn:xmpp:ozone:say:1"/>'
  end

  it 'should create a correct "say" message for audio' do
    expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1">
  <audio url="http://whatever.you-say-boss.com"/>
</say>
    RESPONSE
    Message::Say.new(:url => 'http://whatever.you-say-boss.com').to_xml.should == expected_response.chomp
  end

  it 'should create a correct "say" message for text' do
    expected_response = <<-RESPONSE
<say xmlns="urn:xmpp:ozone:say:1">
  <speak>Once upon a time there was a message...</speak>
</say>
    RESPONSE
    Message::Say.new(:text => 'Once upon a time there was a message...').to_xml.should == expected_response.chomp
  end

  it 'should create a correct "transfer" message' do
    Message::Transfer.new('tel:+14045551212').to_xml.should == '<transfer xmlns="urn:xmpp:ozone:transfer:1" to="tel:+14045551212"/>'
  end

  it 'should create a correct "transfer" message with options' do
    expected_response = '<transfer xmlns="urn:xmpp:ozone:transfer:1" to="tel:+14045551212" terminator="#"/>'
    Message::Transfer.new('tel:+14045551212', :terminator => "#").to_xml.should == expected_response.chomp
  end
end
