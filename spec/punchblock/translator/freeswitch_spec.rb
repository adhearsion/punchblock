# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    describe Freeswitch do
      let(:connection)    { double 'Connection::Freeswitch' }
      let(:media_engine)  { :flite }
      let(:default_voice) { :hal }

      let(:translator)  { described_class.new connection, media_engine, default_voice }
      let(:stream)      { double 'RubyFS::Stream' }

      before { connection.should_receive(:stream).at_most(:once).and_return stream }

      subject { translator }

      its(:connection)  { should be connection }
      its(:stream)      { should be stream }

      describe '#terminate' do
        it "terminates all calls" do
          call = described_class::Call.new 'foo', subject
          subject.register_call call
          subject.terminate
          call.should_not be_alive
        end
      end

      describe '#execute_command' do
        describe 'with a call command' do
          let(:command) { Command::Answer.new }
          let(:call_id) { 'abc123' }

          it 'executes the call command' do
            subject.wrapped_object.should_receive(:execute_call_command).with do |c|
              c.should be command
              c.target_call_id.should be == call_id
            end
            subject.execute_command command, :call_id => call_id
          end
        end

        describe 'with a global component command' do
          let(:command)       { Component::Stop.new }
          let(:component_id)  { '123abc' }

          it 'executes the component command' do
            subject.wrapped_object.should_receive(:execute_component_command).with do |c|
              c.should be command
              c.component_id.should be == component_id
            end
            subject.execute_command command, :component_id => component_id
          end
        end

        describe 'with a global command' do
          let(:command) { Command::Dial.new }

          it 'executes the command directly' do
            subject.wrapped_object.should_receive(:execute_global_command).with command
            subject.execute_command command
          end
        end
      end

      describe '#register_call' do
        let(:call_id) { 'abc123' }
        let(:call)    { described_class::Call.new call_id, subject }

        before do
          subject.register_call call
        end

        it 'should make the call accessible by ID' do
          subject.call_with_id(call_id).should be call
        end
      end

      describe '#deregister_call' do
        let(:call_id) { 'abc123' }
        let(:call)    { described_class::Call.new call_id, subject }

        before do
          subject.register_call call
        end

        it 'should make the call inaccessible by ID' do
          subject.call_with_id(call_id).should be call
          subject.deregister_call call_id
          subject.call_with_id(call_id).should be_nil
        end
      end

      describe '#register_component' do
        let(:component_id) { 'abc123' }
        let(:component)    { double 'Foo', :id => component_id }

        it 'should make the component accessible by ID' do
          subject.register_component component
          subject.component_with_id(component_id).should be component
        end
      end

      describe '#execute_call_command' do
        let(:call_id) { 'abc123' }
        let(:command) { Command::Answer.new target_call_id: call_id }

        context "with a known call ID" do
          let(:call) { described_class::Call.new 'SIP/foo', subject }

          before do
            command.request!
            call.stub(:id).and_return call_id
            subject.register_call call
          end

          it 'sends the command to the call for execution' do
            call.async.should_receive(:execute_command).once.with command
            subject.execute_call_command command
          end
        end

        let :end_error_event do
          Punchblock::Event::End.new reason: :error, target_call_id: call_id
        end

        context "for an outgoing call which began executing but crashed" do
          let(:dial_command) { Command::Dial.new :to => 'SIP/1234', :from => 'abc123' }

          let(:call_id) { dial_command.response.call_id }

          before do
            stream.as_null_object
            subject.execute_command dial_command
          end

          it 'sends an error in response to the command' do
            call = subject.call_with_id call_id

            call.wrapped_object.define_singleton_method(:oops) do
              raise 'Woops, I died'
            end

            connection.should_receive(:handle_event).once.with end_error_event

            lambda { call.oops }.should raise_error(/Woops, I died/)
            sleep 0.1
            call.should_not be_alive
            subject.call_with_id(call_id).should be_nil

            command.request!
            subject.execute_call_command command
            command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id)
          end
        end

        context "for an incoming call which began executing but crashed" do
          let :es_event do
            RubyFS::Event.new nil, :event_name => 'CHANNEL_PARK', :unique_id => 'abc123'
          end

          let(:call)    { subject.call_with_id('abc123') }
          let(:call_id) { call.id }

          before do
            connection.stub :handle_event
            subject.handle_es_event es_event
            call_id
          end

          it 'sends an error in response to the command' do
            call.wrapped_object.define_singleton_method(:oops) do
              raise 'Woops, I died'
            end

            connection.should_receive(:handle_event).once.with end_error_event

            lambda { call.oops }.should raise_error(/Woops, I died/)
            sleep 0.1
            call.should_not be_alive
            subject.call_with_id(call_id).should be_nil

            command.request!
            subject.execute_call_command command
            command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id)
          end
        end

        context "with an unknown call ID" do
          it 'sends an error in response to the command' do
            command.request!
            subject.execute_call_command command
            command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id, nil)
          end
        end
      end

      describe '#execute_component_command' do
        let(:call)            { Translator::Freeswitch::Call.new 'SIP/foo', subject }
        let(:component_node)  { Component::Output.new }
        let(:component)       { Translator::Freeswitch::Component::Output.new(component_node, call) }

        let(:command) { Component::Stop.new component_id: component.id }

        before do
          command.request!
        end

        context 'with a known component ID' do
          before do
            subject.register_component component
          end

          it 'sends the command to the component for execution' do
            component.async.should_receive(:execute_command).once.with command
            subject.execute_component_command command
          end
        end

        context "with an unknown component ID" do
          it 'sends an error in response to the command' do
            subject.execute_component_command command
            command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{component.id}", nil, component.id)
          end
        end
      end

      describe '#execute_global_command' do
        context 'with a Dial' do
          let :command do
            Command::Dial.new :to => '1234', :from => 'abc123'
          end

          let(:id) { Punchblock.new_uuid }

          before do
            id
            Punchblock.should_receive(:new_uuid).once.and_return id
            command.request!
            stream.as_null_object
          end

          it 'should be able to look up the call by ID' do
            subject.execute_global_command command
            call = subject.call_with_id id
            call.should be_a Freeswitch::Call
            call.translator.should be subject
            call.stream.should be stream
            call.media_engine.should be media_engine
            call.default_voice.should be default_voice
          end

          it 'should instruct the call to send a dial' do
            mock_call = double('Freeswitch::Call').as_null_object
            Freeswitch::Call.should_receive(:new_link).once.and_return mock_call
            mock_call.async.should_receive(:dial).once.with command
            subject.execute_global_command command
          end
        end

        context "with a command we don't understand" do
          let :command do
            Command::Answer.new
          end

          it 'sends an error in response to the command' do
            subject.execute_command command
            command.response.should be == ProtocolError.new.setup('command-not-acceptable', "Did not understand command")
          end
        end
      end

      describe '#handle_pb_event' do
        it 'should forward the event to the connection' do
          event = double 'Punchblock::Event'
          subject.connection.should_receive(:handle_event).once.with event
          subject.handle_pb_event event
        end
      end

      describe '#handle_es_event' do
        before { subject.wrapped_object.stub :handle_pb_event }

        let(:unique_id) { "3f0e1e18-c056-11e1-b099-fffeda3ce54f" }

        let :es_env do
          {
            :variable_direction                   => "inbound",
            :variable_uuid                        => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :variable_session_id                  => "1",
            :variable_sip_local_network_addr      => "109.148.160.137",
            :variable_sip_network_ip              => "192.168.1.74",
            :variable_sip_network_port            => "59253",
            :variable_sip_received_ip             => "192.168.1.74",
            :variable_sip_received_port           => "59253",
            :variable_sip_via_protocol            => "udp",
            :variable_sip_authorized              => "true",
            :variable_sip_number_alias            => "1000",
            :variable_sip_auth_username           => "1000",
            :variable_sip_auth_realm              => "127.0.0.1",
            :variable_number_alias                => "1000",
            :variable_user_name                   => "1000",
            :variable_domain_name                 => "127.0.0.1",
            :variable_record_stereo               => "true",
            :variable_default_gateway             => "example.com",
            :variable_default_areacode            => "918",
            :variable_transfer_fallback_extension => "operator",
            :variable_toll_allow                  => "domestic,international,local",
            :variable_accountcode                 => "1000",
            :variable_user_context                => "default",
            :variable_effective_caller_id_name    => "Extension 1000",
            :variable_effective_caller_id_number  => "1000",
            :variable_outbound_caller_id_name     => "FreeSWITCH",
            :variable_outbound_caller_id_number   => "0000000000",
            :variable_callgroup                   => "techsupport",
            :variable_sip_from_user               => "1000",
            :variable_sip_from_uri                => "1000@127.0.0.1",
            :variable_sip_from_host               => "127.0.0.1",
            :variable_sip_from_user_stripped      => "1000",
            :variable_sip_from_tag                => "1248111553",
            :variable_sofia_profile_name          => "internal",
            :variable_sip_full_via                => "SIP/2.0/UDP 192.168.1.74:59253;rport=59253;branch=z9hG4bK2021947958",
            :variable_sip_full_from               => "<sip:1000@127.0.0.1>;tag=1248111553",
            :variable_sip_full_to                 => "<sip:10@127.0.0.1>",
            :variable_sip_req_user                => "10",
            :variable_sip_req_uri                 => "10@127.0.0.1",
            :variable_sip_req_host                => "127.0.0.1",
            :variable_sip_to_user                 => "10",
            :variable_sip_to_uri                  => "10@127.0.0.1",
            :variable_sip_to_host                 => "127.0.0.1",
            :variable_sip_contact_user            => "1000",
            :variable_sip_contact_port            => "59253",
            :variable_sip_contact_uri             => "1000@192.168.1.74:59253",
            :variable_sip_contact_host            => "192.168.1.74",
            :variable_channel_name                => "sofia/internal/1000@127.0.0.1",
            :variable_sip_call_id                 => "1251435211@127.0.0.1",
            :variable_sip_user_agent              => "YATE/4.1.0",
            :variable_sip_via_host                => "192.168.1.74",
            :variable_sip_via_port                => "59253",
            :variable_sip_via_rport               => "59253",
            :variable_max_forwards                => "20",
            :variable_presence_id                 => "1000@127.0.0.1",
            :variable_switch_r_sdp                => "v=0\r\no=yate 1340801245 1340801245 IN IP4 172.20.10.3\r\ns=SIP Call\r\nc=IN IP4 172.20.10.3\r\nt=0 0\r\nm=audio 25048 RTP/AVP 0 8 11 98 97 102 103 104 105 106 101\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:11 L16/8000\r\na=rtpmap:98 iLBC/8000\r\na=fmtp:98 mode=20\r\na=rtpmap:97 iLBC/8000\r\na=fmtp:97 mode=30\r\na=rtpmap:102 SPEEX/8000\r\na=rtpmap:103 SPEEX/16000\r\na=rtpmap:104 SPEEX/32000\r\na=rtpmap:105 iSAC/16000\r\na=rtpmap:106 iSAC/32000\r\na=rtpmap:101 telephone-event/8000\r\na=ptime:30\r\n",
            :variable_remote_media_ip             => "172.20.10.3",
            :variable_remote_media_port           => "25048",
            :variable_sip_audio_recv_pt           => "0",
            :variable_sip_use_codec_name          => "PCMU",
            :variable_sip_use_codec_rate          => "8000",
            :variable_sip_use_codec_ptime         => "30",
            :variable_read_codec                  => "PCMU",
            :variable_read_rate                   => "8000",
            :variable_write_codec                 => "PCMU",
            :variable_write_rate                  => "8000",
            :variable_endpoint_disposition        => "RECEIVED",
            :variable_call_uuid                   => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :variable_open                        => "true",
            :variable_rfc2822_date                => "Wed, 27 Jun 2012 13:47:25 +0100",
            :variable_export_vars                 => "RFC2822_DATE",
            :variable_current_application         => "park"
          }
        end

        let :es_content do
          {
            :event_name                         =>  "CHANNEL_PARK",
            :core_uuid                          =>  "2ad09a34-c056-11e1-b095-fffeda3ce54f",
            :freeswitch_hostname                =>  "blmbp.home",
            :freeswitch_switchname              =>  "blmbp.home",
            :freeswitch_ipv4                    =>  "192.168.1.74",
            :freeswitch_ipv6                    =>  "%3A%3A1",
            :event_date_local                   =>  "2012-06-27%2013%3A47%3A25",
            :event_date_gmt                     =>  "Wed,%2027%20Jun%202012%2012%3A47%3A25%20GMT",
            :event_date_timestamp               =>  "1340801245553845",
            :event_calling_file                 =>  "switch_ivr.c",
            :event_calling_function             =>  "switch_ivr_park",
            :event_calling_line_number          =>  "879",
            :event_sequence                     =>  "485",
            :channel_state                      =>  "CS_EXECUTE",
            :channel_call_state                 =>  "RINGING",
            :channel_state_number               =>  "4",
            :channel_name                       =>  "sofia/internal/1000%40127.0.0.1",
            :unique_id                          =>  "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :call_direction                     =>  "inbound",
            :presence_call_direction            =>  "inbound",
            :channel_hit_dialplan               =>  "true",
            :channel_presence_id                =>  "1000%40127.0.0.1",
            :channel_call_uuid                  =>  "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :answer_state                       =>  "ringing",
            :channel_read_codec_name            =>  "PCMU",
            :channel_read_codec_rate            =>  "8000",
            :channel_read_codec_bit_rate        =>  "64000",
            :channel_write_codec_name           =>  "PCMU",
            :channel_write_codec_rate           =>  "8000",
            :channel_write_codec_bit_rate       =>  "64000",
            :caller_direction                   =>  "inbound",
            :caller_username                    =>  "1000",
            :caller_dialplan                    =>  "XML",
            :caller_caller_id_name              =>  "1000",
            :caller_caller_id_number            =>  "1000",
            :caller_network_addr                =>  "192.168.1.74",
            :caller_ani                         =>  "1000",
            :caller_destination_number          =>  "10",
            :caller_unique_id                   =>  "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :caller_source                      =>  "mod_sofia",
            :caller_context                     =>  "default",
            :caller_channel_name                =>  "sofia/internal/1000%40127.0.0.1",
            :caller_profile_index               =>  "1",
            :caller_profile_created_time        =>  "1340801245532983",
            :caller_channel_created_time        =>  "1340801245532983",
            :caller_channel_answered_time       =>  "0",
            :caller_channel_progress_time       =>  "0",
            :caller_channel_progress_media_time =>  "0",
            :caller_channel_hangup_time         =>  "0",
            :caller_channel_transfer_time       =>  "0",
            :caller_screen_bit                  =>  "true",
            :caller_privacy_hide_name           =>  "false",
            :caller_privacy_hide_number         =>  "false"
          }.merge es_env
        end

        let :es_event do
          RubyFS::Event.new nil, es_content
        end

        it 'should be able to look up the call by ID' do
          subject.handle_es_event es_event
          call = subject.call_with_id unique_id
          call.should be_a Freeswitch::Call
          call.translator.should be subject
          call.stream.should be stream
          call.media_engine.should be media_engine
          call.default_voice.should be default_voice
          call.es_env.should be ==  {
            :variable_direction                   => "inbound",
            :variable_uuid                        => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :variable_session_id                  => "1",
            :variable_sip_local_network_addr      => "109.148.160.137",
            :variable_sip_network_ip              => "192.168.1.74",
            :variable_sip_network_port            => "59253",
            :variable_sip_received_ip             => "192.168.1.74",
            :variable_sip_received_port           => "59253",
            :variable_sip_via_protocol            => "udp",
            :variable_sip_authorized              => "true",
            :variable_sip_number_alias            => "1000",
            :variable_sip_auth_username           => "1000",
            :variable_sip_auth_realm              => "127.0.0.1",
            :variable_number_alias                => "1000",
            :variable_user_name                   => "1000",
            :variable_domain_name                 => "127.0.0.1",
            :variable_record_stereo               => "true",
            :variable_default_gateway             => "example.com",
            :variable_default_areacode            => "918",
            :variable_transfer_fallback_extension => "operator",
            :variable_toll_allow                  => "domestic,international,local",
            :variable_accountcode                 => "1000",
            :variable_user_context                => "default",
            :variable_effective_caller_id_name    => "Extension 1000",
            :variable_effective_caller_id_number  => "1000",
            :variable_outbound_caller_id_name     => "FreeSWITCH",
            :variable_outbound_caller_id_number   => "0000000000",
            :variable_callgroup                   => "techsupport",
            :variable_sip_from_user               => "1000",
            :variable_sip_from_uri                => "1000@127.0.0.1",
            :variable_sip_from_host               => "127.0.0.1",
            :variable_sip_from_user_stripped      => "1000",
            :variable_sip_from_tag                => "1248111553",
            :variable_sofia_profile_name          => "internal",
            :variable_sip_full_via                => "SIP/2.0/UDP 192.168.1.74:59253;rport=59253;branch=z9hG4bK2021947958",
            :variable_sip_full_from               => "<sip:1000@127.0.0.1>;tag=1248111553",
            :variable_sip_full_to                 => "<sip:10@127.0.0.1>",
            :variable_sip_req_user                => "10",
            :variable_sip_req_uri                 => "10@127.0.0.1",
            :variable_sip_req_host                => "127.0.0.1",
            :variable_sip_to_user                 => "10",
            :variable_sip_to_uri                  => "10@127.0.0.1",
            :variable_sip_to_host                 => "127.0.0.1",
            :variable_sip_contact_user            => "1000",
            :variable_sip_contact_port            => "59253",
            :variable_sip_contact_uri             => "1000@192.168.1.74:59253",
            :variable_sip_contact_host            => "192.168.1.74",
            :variable_channel_name                => "sofia/internal/1000@127.0.0.1",
            :variable_sip_call_id                 => "1251435211@127.0.0.1",
            :variable_sip_user_agent              => "YATE/4.1.0",
            :variable_sip_via_host                => "192.168.1.74",
            :variable_sip_via_port                => "59253",
            :variable_sip_via_rport               => "59253",
            :variable_max_forwards                => "20",
            :variable_presence_id                 => "1000@127.0.0.1",
            :variable_switch_r_sdp                => "v=0\r\no=yate 1340801245 1340801245 IN IP4 172.20.10.3\r\ns=SIP Call\r\nc=IN IP4 172.20.10.3\r\nt=0 0\r\nm=audio 25048 RTP/AVP 0 8 11 98 97 102 103 104 105 106 101\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:11 L16/8000\r\na=rtpmap:98 iLBC/8000\r\na=fmtp:98 mode=20\r\na=rtpmap:97 iLBC/8000\r\na=fmtp:97 mode=30\r\na=rtpmap:102 SPEEX/8000\r\na=rtpmap:103 SPEEX/16000\r\na=rtpmap:104 SPEEX/32000\r\na=rtpmap:105 iSAC/16000\r\na=rtpmap:106 iSAC/32000\r\na=rtpmap:101 telephone-event/8000\r\na=ptime:30\r\n",
            :variable_remote_media_ip             => "172.20.10.3",
            :variable_remote_media_port           => "25048",
            :variable_sip_audio_recv_pt           => "0",
            :variable_sip_use_codec_name          => "PCMU",
            :variable_sip_use_codec_rate          => "8000",
            :variable_sip_use_codec_ptime         => "30",
            :variable_read_codec                  => "PCMU",
            :variable_read_rate                   => "8000",
            :variable_write_codec                 => "PCMU",
            :variable_write_rate                  => "8000",
            :variable_endpoint_disposition        => "RECEIVED",
            :variable_call_uuid                   => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :variable_open                        => "true",
            :variable_rfc2822_date                => "Wed, 27 Jun 2012 13:47:25 +0100",
            :variable_export_vars                 => "RFC2822_DATE",
            :variable_current_application         => "park"
          }
        end

        describe "with a RubyFS::Stream::Connected" do
          let(:es_event) { RubyFS::Stream::Connected.new }

          it "should send a Punchblock::Connection::Connected event" do
            subject.wrapped_object.should_receive(:handle_pb_event).once.with(Punchblock::Connection::Connected.new)
            subject.handle_es_event es_event
          end
        end

        describe "with a RubyFS::Stream::Disconnected" do
          let(:es_event) { RubyFS::Stream::Disconnected.new }

          it "should not raise an error" do
            subject.handle_es_event es_event
          end
        end

        describe 'with a CHANNEL_PARK event' do
          it 'should instruct the call to send an offer' do
            mock_call = double('Freeswitch::Call').as_null_object
            Freeswitch::Call.should_receive(:new).once.and_return mock_call
            subject.wrapped_object.should_receive(:link)
            mock_call.async.should_receive(:send_offer).once
            subject.handle_es_event es_event
          end

          context 'if a call already exists for a matching ID' do
            let(:call) { Freeswitch::Call.new unique_id, subject }

            before do
              subject.register_call call
            end

            it "should not create a new call" do
              Freeswitch::Call.should_receive(:new).never
              subject.handle_es_event es_event
            end
          end
        end

        describe "with a CHANNEL_BRIDGE event" do
          describe 'with an Other-Leg-Unique-ID value' do
            let(:call_a) { Freeswitch::Call.new Punchblock.new_uuid, subject }
            let(:call_b) { Freeswitch::Call.new Punchblock.new_uuid, subject }

            before do
              subject.register_call call_a
              subject.register_call call_b
            end

            let :es_event do
              RubyFS::Event.new nil, {
                :event_name           => 'CHANNEL_BRIDGE',
                :unique_id            => call_a.id,
                :other_leg_unique_id  => call_b.id
              }
            end

            it "is delivered to the bridging leg" do
              call_a.async.should_receive(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end

            it "is delivered to the other leg" do
              call_b.async.should_receive(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end
          end
        end

        describe "with a CHANNEL_UNBRIDGE event" do
          describe 'with an Other-Leg-Unique-ID value' do
            let(:call_a) { Freeswitch::Call.new Punchblock.new_uuid, subject }
            let(:call_b) { Freeswitch::Call.new Punchblock.new_uuid, subject }

            before do
              subject.register_call call_a
              subject.register_call call_b
            end

            let :es_event do
              RubyFS::Event.new nil, {
                :event_name           => 'CHANNEL_UNBRIDGE',
                :unique_id            => call_a.id,
                :other_leg_unique_id  => call_b.id
              }
            end

            it "is delivered to the bridging leg" do
              call_a.async.should_receive(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end

            it "is delivered to the other leg" do
              call_b.async.should_receive(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end
          end
        end

        describe 'with an Other-Leg-Unique-ID value' do
          let(:call_a) { Freeswitch::Call.new Punchblock.new_uuid, subject }
          let(:call_b) { Freeswitch::Call.new Punchblock.new_uuid, subject }

          before do
            subject.register_call call_a
            subject.register_call call_b
          end

          let :es_event do
            RubyFS::Event.new nil, {
              :unique_id            => call_a.id,
              :other_leg_unique_id  => call_b.id
            }
          end

          it "is delivered only to the primary leg" do
            call_a.async.should_receive(:handle_es_event).once.with es_event
            call_b.async.should_receive(:handle_es_event).never
            subject.handle_es_event es_event
          end
        end

        describe 'with an ES event for a known ID' do
          let :call do
            Freeswitch::Call.new unique_id, subject
          end

          before do
            subject.register_call call
          end

          it 'sends the ES event to the call' do
            call.async.should_receive(:handle_es_event).once.with es_event
            subject.handle_es_event es_event
          end
        end
      end
    end
  end
end
