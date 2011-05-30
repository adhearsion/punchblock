require 'spec_helper'

describe 'XMPP Transport' do
  before :all do
    @module = Punchblock::Transport::XMPP
    @generic_protocol = Punchblock::Protocol::GenericProtocol
  end

  it 'should require a username and password to be passed in the options' do
    expect { @module.new @generic_protocol, {:password => 1} }.to raise_error ArgumentError
    expect { @module.new @generic_protocol, {:username => 1} }.to raise_error ArgumentError
  end

  it 'should properly set the Blather logger' do
    transport = @module.new @generic_protocol, {:wire_logger => :foo, :username => 1, :password => 1}
    Blather.logger.should be :foo
  end

  it 'should create an event queue' do
    transport = @module.new @generic_protocol, {:username => 1, :password => 1}
    transport.event_queue.should be_a Queue
  end

  it 'should properly locate a protocol' do
    transport = @module.new :ozone, {:username => 1, :password => 1}
    transport.instance_variable_get(:@protocol).should be Punchblock::Protocol::Ozone
  end

  describe 'Blather messages' do
    before :all do
    offer_xml = <<-MSG
<iq type="set" from="432ef388-9c53-4e11-b00e-10823988173d@127.0.0.1" to="usera@127.0.0.1/voxeo" id="7efae189-7df4-4b1b-8f8a-690c0efa6208">
  <offer xmlns="urn:xmpp:ozone:1" to="sip:12345@127.0.0.1" from="sip:bob@127.0.0.1">
    <header name="Max-Forwards" value="70"/>
    <header name="Content-Length" value="441"/>
    <header name="Contact" value="&lt;sip:yizjrshk@127.0.0.1:51623&gt;"/>
    <header name="Supported" value="100rel"/>
    <header name="Allow" value="SUBSCRIBE"/>
    <header name="To" value="&lt;sip:12345@127.0.0.1&gt;"/>
    <header name="CSeq" value="22785 INVITE"/>
    <header name="User-Agent" value="Blink Pro 1.0.9 (MacOSX)"/>
    <header name="Via" value="SIP/2.0/UDP 192.168.106.1:51623;rport=51623;branch=z9hG4bKPjLeJH8HnPWY9wqE5E3.IOfX4LlNgjAAnq;received=127.0.0.1"/>
    <header name="Call-ID" value="C0wfPc9PDHjEac-1XafDgQWjvT1IbWwP"/>
    <header name="Content-Type" value="application/sdp"/>
    <header name="From" value="&quot;Ozone Bob&quot; &lt;sip:bob@127.0.0.1&gt;;tag=t0aZe1erkGhIwNhIBH.JkXEjjEsGoAAa"/>
  </offer>
</iq>
      MSG
      @example_offer = Nokogiri::XML.parse(offer_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).children.first
      @transport = @module.new @generic_protocol, {:username => 1, :password => 1}
    end

    it 'should call the protocol parser with the correct arguments' do
      flexmock(@generic_protocol::Message).should_receive(:parse).once.with('432ef388-9c53-4e11-b00e-10823988173d', nil, /^<offer xmlns=/)
      flexmock(@example_offer).should_receive(:reply!)
      flexmock(@transport).should_receive(:write_to_stream)
      @transport.read @example_offer
    end
  end

end
