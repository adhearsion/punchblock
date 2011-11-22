require 'spec_helper'

module Punchblock
  module Connection
    describe XMPP do
      let(:connection) { XMPP.new :username => '1@call.rayo.net', :password => 1 }

      let(:mock_event_handler) { stub_everything 'Event Handler' }

      before do
        connection.event_handler = mock_event_handler
      end

      subject { connection }

      it 'should require a username and password to be passed in the options' do
        expect { XMPP.new :password => 1 }.to raise_error ArgumentError
        expect { XMPP.new :username => 1 }.to raise_error ArgumentError
      end

      it 'should properly set the Blather logger' do
        Punchblock.logger = :foo
        XMPP.new :username => '1@call.rayo.net', :password => 1
        Blather.logger.should be :foo
        Punchblock.reset_logger
      end

      it "looking up original command by command ID" do
        pending
        offer = Event::Offer.new
        offer.call_id = '9f00061'
        offer.to = 'sip:whatever@127.0.0.1'
        say = <<-MSG
<say xmlns='urn:xmpp:tropo:say:1' voice='allison'>
  <audio url='http://acme.com/greeting.mp3'>
  Thanks for calling ACME company
  </audio>
  <audio url='http://acme.com/package-shipped.mp3'>
  Your package was shipped on
  </audio>
  <say-as interpret-as='date'>12/01/2011</say-as>
</say>
        MSG
        Component::Tropo::Say
        say = RayoNode.import parse_stanza(say).root
        connection.expects(:write_to_stream).once.returns true
        iq = Blather::Stanza::Iq.new :set, '9f00061@call.rayo.net'
        connection.expects(:create_iq).returns iq

        write_thread = Thread.new do
          connection.write offer.call_id, say
        end

        result = import_stanza <<-MSG
<iq type='result' from='16577@app.rayo.net/1' to='9f00061@call.rayo.net/1' id='#{iq.id}'>
  <ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />
</iq>
        MSG

        sleep 0.5 # Block so there's enough time for the write thread to get to the point where it's waiting on an IQ

        connection.__send__ :handle_iq_result, result

        write_thread.join

        say.state_name.should == :executing

        connection.original_component_from_id('fgh4590').should == say

        example_complete = import_stanza <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:tropo:say:complete:1' />
  </complete>
</presence>
        MSG

        connection.__send__ :handle_presence, example_complete
        say.complete_event(0.5).source.should == say

        say.component_id.should == 'fgh4590'
      end

      describe '#handle_presence' do
        let :offer_xml do
          <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net'>
  <offer xmlns="urn:xmpp:rayo:1" to="sip:whatever@127.0.0.1" from="sip:ylcaomxb@192.168.1.9">
  <header name="Max-Forwards" value="70"/>
  <header name="Content-Length" value="367"/>
  </offer>
</presence>
          MSG
        end

        let(:example_offer) { import_stanza offer_xml }

        it { example_offer.should be_a Blather::Stanza::Presence }

        let :complete_xml do
          <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:tropo:say:complete:1' />
  </complete>
</presence>
          MSG
        end

        let(:example_complete) { import_stanza complete_xml }

        it { example_complete.should be_a Blather::Stanza::Presence }

        describe "presence received" do
          describe "from an offer" do
            let(:handle_presence) { connection.__send__ :handle_presence, example_offer }

            it 'should call the event handler with the event' do
              mock_event_handler.expects(:call).once.with do |event|
                event.should be_instance_of Event::Offer
                event.call_id.should == '9f00061'
                event.domain.should == 'call.rayo.net'
              end
              handle_presence
            end

            it "should populate the call map with the domain for the call ID" do
              handle_presence
              callmap = connection.instance_variable_get(:'@callmap')
              callmap['9f00061'].should == 'call.rayo.net'
            end
          end

          describe "from something that's not a real event" do
            let :irrelevant_xml do
              <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <foo/>
</presence>
              MSG
            end

            let(:example_irrelevant_event) { import_stanza irrelevant_xml }

            it 'should not handle the event' do
              mock_event_handler.expects(:call).never
              lambda { connection.__send__ :handle_presence, example_irrelevant_event }.should throw_symbol(:pass)
            end
          end
        end
      end

      describe "#handle_error" do
        let(:call_id)       { "f6d437f4-1e18-457b-99f8-b5d853f50347" }
        let(:component_id)  { 'abc123' }
        let :error_xml do
          <<-MSG
<iq type="error" id="blather000e" from="f6d437f4-1e18-457b-99f8-b5d853f50347@10.0.1.11/abc123" to="usera@10.0.1.11/voxeo">
  <output xmlns="urn:xmpp:rayo:output:1"/>
  <error type="cancel">
    <item-not-found xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
    <text xmlns="urn:ietf:params:xml:ns:xmpp-stanzas" lang="en">Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]</text>
  </error>
</iq>
          MSG
        end

        let(:example_error) { import_stanza error_xml }
        let(:cmd) { Component::Output.new }

        before(:all) do
          cmd.request!
          connection.__send__ :handle_error, example_error, cmd
        end

        subject { cmd.response }

        its(:call_id)       { should == call_id }
        its(:component_id)  { should == component_id }
        its(:name)          { should == :item_not_found }
        its(:text)          { should == 'Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]' }
      end
    end # describe XMPP
  end # XMPP
end # Punchblock
