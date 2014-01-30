# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Connection
    describe XMPP do
      let(:options)     { { :root_domain => 'rayo.net' } }
      let(:connection)  { XMPP.new({:username => '1@app.rayo.net', :password => 1}.merge(options)) }

      let(:mock_event_handler) { double('Event Handler').as_null_object }

      before do
        connection.event_handler = mock_event_handler
      end

      subject { connection }

      describe "rayo domains" do
        context "with no domains specified, and a JID of 1@app.rayo.net" do
          let(:options) { { :username => '1@app.rayo.net' } }

          its(:root_domain)   { should be == 'app.rayo.net' }
        end

        context "with only a rayo domain set" do
          let(:options) { { :rayo_domain => 'rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
        end

        context "with only a root domain set" do
          let(:options) { { :root_domain => 'rayo.org' } }

          its(:root_domain)   { should be == 'rayo.org' }
        end
      end

      it 'should require a username and password to be passed in the options' do
        expect { XMPP.new :password => 1 }.to raise_error ArgumentError
        expect { XMPP.new :username => 1 }.to raise_error ArgumentError
      end

      it 'should properly set the Blather logger' do
        old_logger = Punchblock.logger
        Punchblock.logger = :foo
        XMPP.new :username => '1@call.rayo.net', :password => 1
        Blather.logger.should be :foo
        Punchblock.logger = old_logger
      end

      it "looking up original command by command ID" do
        pending
        offer = Event::Offer.new
        offer.call_id = '9f00061'
        offer.to = 'sip:whatever@127.0.0.1'
        output = <<-MSG
<output xmlns='urn:xmpp:rayo:output:1'>
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
        connection.should_receive(:write_to_stream).once.and_return true
        iq = Blather::Stanza::Iq.new :set, '9f00061@call.rayo.net'
        connection.should_receive(:create_iq).and_return iq

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
        client.should_receive(:write).once.with do |stanza|
          stanza.to.should be == 'rayo.net'
          stanza.should be_a Blather::Stanza::Presence::Status
          stanza.chat?.should be true
        end
        connection.ready!
      end

      it 'should send a "Do Not Disturb" presence when not_ready' do
        client = connection.send :client
        client.should_receive(:write).once.with do |stanza|
          stanza.to.should be == 'rayo.net'
          stanza.should be_a Blather::Stanza::Presence::Status
          stanza.dnd?.should be true
        end
        connection.not_ready!
      end

      describe '#send_message' do
        it 'should send a "normal" message to the given user and domain' do
          client = connection.send :client
          client.should_receive(:write).once.with do |stanza|
            stanza.to.should be == 'someone@example.org'
            stanza.should be_a Blather::Stanza::Message
            stanza.type.should == :normal
            stanza.body.should be == 'Hello World!'
            stanza.subject.should be_nil
          end
          connection.send_message 'someone', 'example.org', 'Hello World!'
        end

        it 'should default to the root domain' do
          client = connection.send :client
          client.should_receive(:write).once.with do |stanza|
            stanza.to.should be == 'someone@rayo.net'
          end
          connection.send_message "someone", nil, nil
        end

        it 'should send a message with the given subject' do
          client = connection.send :client
          client.should_receive(:write).once.with do |stanza|
            stanza.subject.should be == "Important Message"
          end
          connection.send_message nil, nil, nil, :subject => "Important Message"
        end
      end

      describe '#handle_presence' do
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

        describe "accessing the rayo node for a presence stanza" do
          it "should import the rayo node" do
            example_complete.rayo_node.should be_a Punchblock::Event::Complete
          end

          it "should be memoized" do
            example_complete.rayo_node.should be example_complete.rayo_node
          end
        end

        describe "presence received" do
          let(:handle_presence) { connection.__send__ :handle_presence, example_event }

          describe "from an offer" do
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

            let(:example_event) { import_stanza offer_xml }

            it { example_event.should be_a Blather::Stanza::Presence }

            it 'should call the event handler with the event' do
              mock_event_handler.should_receive(:call).once.with do |event|
                event.should be_instance_of Event::Offer
                event.target_call_id.should be == '9f00061'
                event.source_uri.should be == 'xmpp:9f00061@call.rayo.net'
                event.domain.should be == 'call.rayo.net'
                event.transport.should be == 'xmpp'
              end
              handle_presence
            end
          end

          describe "from something that's not a real event" do
            let :irrelevant_xml do
              <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <foo bar="baz"/>
</presence>
              MSG
            end

            let(:example_event) { import_stanza irrelevant_xml }

            it 'should not be considered to be a rayo event' do
              example_event.rayo_event?.should be_false
            end

            it 'should have a nil rayo_node' do
              example_event.rayo_node.should be_nil
            end

            it 'should not handle the event' do
              mock_event_handler.should_receive(:call).never
              lambda { handle_presence }.should throw_symbol(:pass)
            end
          end
        end
      end

      describe "#handle_error" do
        let(:call_id)       { "f6d437f4-1e18-457b-99f8-b5d853f50347" }
        let(:component_id)  { 'abc123' }
        let :error_xml do
          <<-MSG
<iq type="error" id="blather000e" from="f6d437f4-1e18-457b-99f8-b5d853f50347@call.rayo.net/abc123" to="usera@rayo.net">
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

        before do
          cmd.request!
          connection.__send__ :handle_error, example_error, cmd
        end

        subject { cmd.response }

        it "should have the correct call ID" do
          subject.call_id.should be == call_id
        end

        it "should have the correct component ID" do
          subject.component_id.should be == component_id
        end

        it "should have the correct name" do
          subject.name.should be == :item_not_found
        end

        it "should have the correct text" do
          subject.text.should be == 'Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]'
        end
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
          let(:command)       { Command::Answer.new target_call_id: 'abc123' }
          let(:expected_jid)  { 'abc123@rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end

          context "with a domain specified" do
            let(:expected_jid)  { 'abc123@calls.rayo.net' }

            it "should use the specified domain in the JID" do
              stanza = subject.prep_command_for_execution command, domain: 'calls.rayo.net'
              stanza.to.should be == expected_jid
            end
          end
        end

        context "with a call component" do
          let(:command)       { Component::Output.new :target_call_id => 'abc123' }
          let(:expected_jid)  { 'abc123@rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a call component command" do
          let(:command)       { Component::Stop.new :target_call_id => 'abc123', :component_id => 'foobar' }
          let(:expected_jid)  { 'abc123@rayo.net/foobar' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a mixer component" do
          let(:command)       { Component::Output.new :target_mixer_name => 'abc123' }
          let(:expected_jid)  { 'abc123@rayo.net' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end

        context "with a mixer component command" do
          let(:command)       { Component::Stop.new :target_mixer_name => 'abc123', :component_id => 'foobar' }
          let(:expected_jid)  { 'abc123@rayo.net/foobar' }

          it "should use the correct JID" do
            stanza.to.should be == expected_jid
          end
        end
      end

      describe "receiving events from a mixer" do
        context "after joining the mixer" do
          before do
            subject.send(:client).should_receive :write_with_handler
            subject.write Command::Join.new(:mixer_name => 'foomixer')
          end

          let :active_speaker_xml do
            <<-MSG
<presence to='16577@app.rayo.net/1' from='foomixer@rayo.net'>
  <started-speaking xmlns="urn:xmpp:rayo:1" call-id="foocall"/>
</presence>
            MSG
          end

          let(:active_speaker_event) { import_stanza active_speaker_xml }

          it "should tag those events with a mixer name, rather than a call ID" do
            mock_event_handler.should_receive(:call).once.with do |event|
              event.should be_instance_of Event::StartedSpeaking
              event.target_mixer_name.should be == 'foomixer'
              event.target_call_id.should be nil
              event.domain.should be == 'rayo.net'
            end
            connection.__send__ :handle_presence, active_speaker_event
          end
        end
      end
    end # describe XMPP
  end # XMPP
end # Punchblock
