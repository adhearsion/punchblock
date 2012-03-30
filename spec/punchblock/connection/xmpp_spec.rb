# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Connection
    describe XMPP do
      let(:options)     { { :root_domain => 'rayo.net' } }
      let(:connection)  { XMPP.new({:username => '1@app.rayo.net', :password => 1}.merge(options)) }

      let(:mock_event_handler) { stub_everything 'Event Handler' }

      before do
        connection.event_handler = mock_event_handler
      end

      subject { connection }

      describe "rayo domains" do
        context "with no domains specified, and a JID of 1@app.rayo.net" do
          let(:options) { { :username => '1@app.rayo.net' } }

          its(:root_domain)   { should be == 'app.rayo.net' }
          its(:calls_domain)  { should be == 'calls.app.rayo.net' }
          its(:mixers_domain) { should be == 'mixers.app.rayo.net' }
        end

        context "with only a rayo domain set" do
          let(:options) { { :rayo_domain => 'rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
          its(:calls_domain)  { should be == 'calls.rayo.org' }
          its(:mixers_domain) { should be == 'mixers.rayo.org' }
        end

        context "with only a root domain set" do
          let(:options) { { :root_domain => 'rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
          its(:calls_domain)  { should be == 'calls.rayo.org' }
          its(:mixers_domain) { should be == 'mixers.rayo.org' }
        end

        context "with a root domain and calls domain set" do
          let(:options) { { :root_domain => 'rayo.org', :calls_domain => 'phone_calls.rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
          its(:calls_domain)  { should be == 'phone_calls.rayo.org' }
          its(:mixers_domain) { should be == 'mixers.rayo.org' }
        end

        context "with a root domain and mixers domain set" do
          let(:options) { { :root_domain => 'rayo.org', :mixers_domain => 'conferences.rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
          its(:calls_domain)  { should be == 'calls.rayo.org' }
          its(:mixers_domain) { should be == 'conferences.rayo.org' }
        end
      end

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
        output = <<-MSG
<output xmlns='urn:xmpp:tropo:say:1'>
  <audio url='http://acme.com/greeting.mp3'>
  Thanks for calling ACME company
  </audio>
  <audio url='http://acme.com/package-shipped.mp3'>
  Your package was shipped on
  </audio>
  <say-as interpret-as='date'>12/01/2011</say-as>
</output>
        MSG
        output = RayoNode.import parse_stanza(output).root
        connection.expects(:write_to_stream).once.returns true
        iq = Blather::Stanza::Iq.new :set, '9f00061@call.rayo.net'
        connection.expects(:create_iq).returns iq

        write_thread = Thread.new do
          connection.write offer.call_id, output
        end

        result = import_stanza <<-MSG
<iq type='result' from='16577@app.rayo.net/1' to='9f00061@call.rayo.net/1' id='#{iq.id}'>
  <ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />
</iq>
        MSG

        sleep 0.5 # Block so there's enough time for the write thread to get to the point where it's waiting on an IQ

        connection.__send__ :handle_iq_result, result

        write_thread.join

        output.state_name.should be == :executing

        connection.original_component_from_id('fgh4590').should be == output

        example_complete = import_stanza <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:rayo:output:complete:1' />
  </complete>
</presence>
        MSG

        connection.__send__ :handle_presence, example_complete
        output.complete_event(0.5).source.should be == output

        output.component_id.should be == 'fgh4590'
      end

      it 'should send a "Chat" presence when ready' do
        client = connection.send :client
        client.expects(:write).once.with do |stanza|
          stanza.to.should be == 'rayo.net'
          stanza.should be_a Blather::Stanza::Presence::Status
          stanza.chat?.should be true
        end
        connection.ready!
      end

      it 'should send a "Do Not Disturb" presence when not_ready' do
        client = connection.send :client
        client.expects(:write).once.with do |stanza|
          stanza.to.should be == 'rayo.net'
          stanza.should be_a Blather::Stanza::Presence::Status
          stanza.dnd?.should be true
        end
        connection.not_ready!
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
  <success xmlns='urn:xmpp:rayo:output:complete:1' />
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
                event.target_call_id.should be == '9f00061'
                event.domain.should be == 'call.rayo.net'
              end
              handle_presence
            end

            it "should populate the call map with the domain for the call ID" do
              handle_presence
              callmap = connection.instance_variable_get(:'@callmap')
              callmap['9f00061'].should be == 'call.rayo.net'
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

        its(:call_id)       { should be == call_id }
        its(:component_id)  { should be == component_id }
        its(:name)          { should be == :item_not_found }
        its(:text)          { should be == 'Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]' }
      end

      describe "#prep_command_for_execution" do
        let(:stanza) { subject.prep_command_for_execution command }

        context "with a dial command" do
          let(:command)       { Command::Dial.new }
          let(:expected_jid)  { 'rayo.net' }

          it "should use the correct JID" do
            stanza = subject.prep_command_for_execution command
            stanza.to.should be == expected_jid
          end
        end

        context "with a call command" do
          let(:command)       { Command::Answer.new.tap { |a| a.target_call_id = 'abc123' } }
          let(:expected_jid)  { 'abc123@calls.rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a call component" do
          let(:command)       { Component::Output.new :target_call_id => 'abc123' }
          let(:expected_jid)  { 'abc123@calls.rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a call component command" do
          let(:command)       { Component::Stop.new :target_call_id => 'abc123', :component_id => 'foobar' }
          let(:expected_jid)  { 'abc123@calls.rayo.net/foobar' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a mixer component" do
          let(:command)       { Component::Output.new :target_mixer_name => 'abc123' }
          let(:expected_jid)  { 'abc123@mixers.rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a mixer component command" do
          let(:command)       { Component::Stop.new :target_mixer_name => 'abc123', :component_id => 'foobar' }
          let(:expected_jid)  { 'abc123@mixers.rayo.net/foobar' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end
      end
    end # describe XMPP
  end # XMPP
end # Punchblock
