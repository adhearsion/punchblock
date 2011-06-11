require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      describe Connection do
        let(:generic_connection) { Punchblock::Protocol::GenericConnection }

        subject { Connection.new :username => 1, :password => 1 }

        it 'should require a username and password to be passed in the options' do
          expect { Connection.new :password => 1 }.to raise_error ArgumentError
          expect { Connection.new :username => 1 }.to raise_error ArgumentError
        end

        it 'should properly set the Blather logger' do
          connection = Connection.new :wire_logger => :foo, :username => 1, :password => 1
          Blather.logger.should be :foo
        end

        its(:event_queue) { should be_a Queue }

        describe 'Blather messages' do
          let :offer_xml do
            <<-MSG
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
          end

          let(:example_offer) { Nokogiri::XML.parse(offer_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).children.first }

          it 'should call the protocol parser with the correct arguments' do
            pending
            flexmock(generic_protocol::Message).should_receive(:parse).once.with('432ef388-9c53-4e11-b00e-10823988173d', nil, /^<offer xmlns=/)
            flexmock(@example_offer).should_receive(:reply!)
            flexmock(@transport).should_receive(:write_to_stream)
            subject.read @example_offer
          end
        end

      end
    end
  end
end
