# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      describe Call do
        let(:id) { Punchblock.new_uuid }
        let(:stream)        { stub('RubyFS::Stream').as_null_object }
        let(:media_engine)  { 'freeswitch' }
        let(:default_voice) { :hal }
        let(:translator)    { Freeswitch.new stub('Connection::Freeswitch').as_null_object }
        let(:es_env) do
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

        let :headers do
          {
            :x_variable_direction                   => "inbound",
            :x_variable_uuid                        => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :x_variable_session_id                  => "1",
            :x_variable_sip_local_network_addr      => "109.148.160.137",
            :x_variable_sip_network_ip              => "192.168.1.74",
            :x_variable_sip_network_port            => "59253",
            :x_variable_sip_received_ip             => "192.168.1.74",
            :x_variable_sip_received_port           => "59253",
            :x_variable_sip_via_protocol            => "udp",
            :x_variable_sip_authorized              => "true",
            :x_variable_sip_number_alias            => "1000",
            :x_variable_sip_auth_username           => "1000",
            :x_variable_sip_auth_realm              => "127.0.0.1",
            :x_variable_number_alias                => "1000",
            :x_variable_user_name                   => "1000",
            :x_variable_domain_name                 => "127.0.0.1",
            :x_variable_record_stereo               => "true",
            :x_variable_default_gateway             => "example.com",
            :x_variable_default_areacode            => "918",
            :x_variable_transfer_fallback_extension => "operator",
            :x_variable_toll_allow                  => "domestic,international,local",
            :x_variable_accountcode                 => "1000",
            :x_variable_user_context                => "default",
            :x_variable_effective_caller_id_name    => "Extension 1000",
            :x_variable_effective_caller_id_number  => "1000",
            :x_variable_outbound_caller_id_name     => "FreeSWITCH",
            :x_variable_outbound_caller_id_number   => "0000000000",
            :x_variable_callgroup                   => "techsupport",
            :x_variable_sip_from_user               => "1000",
            :x_variable_sip_from_uri                => "1000@127.0.0.1",
            :x_variable_sip_from_host               => "127.0.0.1",
            :x_variable_sip_from_user_stripped      => "1000",
            :x_variable_sip_from_tag                => "1248111553",
            :x_variable_sofia_profile_name          => "internal",
            :x_variable_sip_full_via                => "SIP/2.0/UDP 192.168.1.74:59253;rport=59253;branch=z9hG4bK2021947958",
            :x_variable_sip_full_from               => "<sip:1000@127.0.0.1>;tag=1248111553",
            :x_variable_sip_full_to                 => "<sip:10@127.0.0.1>",
            :x_variable_sip_req_user                => "10",
            :x_variable_sip_req_uri                 => "10@127.0.0.1",
            :x_variable_sip_req_host                => "127.0.0.1",
            :x_variable_sip_to_user                 => "10",
            :x_variable_sip_to_uri                  => "10@127.0.0.1",
            :x_variable_sip_to_host                 => "127.0.0.1",
            :x_variable_sip_contact_user            => "1000",
            :x_variable_sip_contact_port            => "59253",
            :x_variable_sip_contact_uri             => "1000@192.168.1.74:59253",
            :x_variable_sip_contact_host            => "192.168.1.74",
            :x_variable_channel_name                => "sofia/internal/1000@127.0.0.1",
            :x_variable_sip_call_id                 => "1251435211@127.0.0.1",
            :x_variable_sip_user_agent              => "YATE/4.1.0",
            :x_variable_sip_via_host                => "192.168.1.74",
            :x_variable_sip_via_port                => "59253",
            :x_variable_sip_via_rport               => "59253",
            :x_variable_max_forwards                => "20",
            :x_variable_presence_id                 => "1000@127.0.0.1",
            :x_variable_switch_r_sdp                => "v=0\r\no=yate 1340801245 1340801245 IN IP4 172.20.10.3\r\ns=SIP Call\r\nc=IN IP4 172.20.10.3\r\nt=0 0\r\nm=audio 25048 RTP/AVP 0 8 11 98 97 102 103 104 105 106 101\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:11 L16/8000\r\na=rtpmap:98 iLBC/8000\r\na=fmtp:98 mode=20\r\na=rtpmap:97 iLBC/8000\r\na=fmtp:97 mode=30\r\na=rtpmap:102 SPEEX/8000\r\na=rtpmap:103 SPEEX/16000\r\na=rtpmap:104 SPEEX/32000\r\na=rtpmap:105 iSAC/16000\r\na=rtpmap:106 iSAC/32000\r\na=rtpmap:101 telephone-event/8000\r\na=ptime:30\r\n",
            :x_variable_remote_media_ip             => "172.20.10.3",
            :x_variable_remote_media_port           => "25048",
            :x_variable_sip_audio_recv_pt           => "0",
            :x_variable_sip_use_codec_name          => "PCMU",
            :x_variable_sip_use_codec_rate          => "8000",
            :x_variable_sip_use_codec_ptime         => "30",
            :x_variable_read_codec                  => "PCMU",
            :x_variable_read_rate                   => "8000",
            :x_variable_write_codec                 => "PCMU",
            :x_variable_write_rate                  => "8000",
            :x_variable_endpoint_disposition        => "RECEIVED",
            :x_variable_call_uuid                   => "3f0e1e18-c056-11e1-b099-fffeda3ce54f",
            :x_variable_open                        => "true",
            :x_variable_rfc2822_date                => "Wed, 27 Jun 2012 13:47:25 +0100",
            :x_variable_export_vars                 => "RFC2822_DATE",
            :x_variable_current_application         => "park"
          }
        end

        subject { Call.new id, translator, es_env, stream, media_engine, default_voice }

        its(:id)            { should be == id }
        its(:translator)    { should be translator }
        its(:es_env)        { should be == es_env }
        its(:stream)        { should be stream }
        its(:media_engine)  { should be media_engine }

        describe '#register_component' do
          it 'should make the component accessible by ID' do
            component_id = 'abc123'
            component    = mock 'Translator::Freeswitch::Component', :id => component_id
            subject.register_component component
            subject.component_with_id(component_id).should be component
          end
        end

        describe '#send_offer' do
          it 'sends an offer to the translator' do
            expected_offer = Punchblock::Event::Offer.new :target_call_id => subject.id,
                                                          :to             => "10@127.0.0.1",
                                                          :from           => "Extension 1000 <1000@127.0.0.1>",
                                                          :headers        => headers
            translator.should_receive(:handle_pb_event).with expected_offer
            subject.send_offer
          end

          it 'should make the call identify as inbound' do
            subject.send_offer
            subject.direction.should be == :inbound
            subject.inbound?.should be true
            subject.outbound?.should be false
          end
        end

        describe "#application" do
          it "should execute a FS application on the current call" do
            stream.should_receive(:application).once.with(id, 'appname', 'options')
            subject.application 'appname', 'options'
          end
        end

        describe "#sendmsg" do
          it "should execute a FS sendmsg on the current call" do
            stream.should_receive(:sendmsg).once.with(id, 'msg', :foo => 'bar')
            subject.sendmsg 'msg', :foo => 'bar'
          end
        end

        describe "#uuid_foo" do
          it "should execute a FS uuid_* on the current call using bgapi" do
            stream.should_receive(:bgapi).once.with("uuid_record #{id} blah.mp3")
            subject.uuid_foo 'record', 'blah.mp3'
          end
        end

        describe '#dial' do
          let(:dial_command_options) { {} }

          let(:to)    { 'sofia/internal/1000' }
          let(:from)  { '1001' }

          let :dial_command do
            Punchblock::Command::Dial.new({:to => to, :from => from}.merge(dial_command_options))
          end

          before { dial_command.request! }

          it 'sends an originate bgapi command' do
            stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_number='#{from}'}#{to} &park()"
            subject.dial dial_command
          end

          context 'with a name and channel in the from field' do
            let(:from_name)   { 'Jane Smith' }
            let(:from_number) { '1001' }
            let(:from)        { "#{from_name} <#{from_number}>" }

            it 'sends an originate bgapi command with the cid fields set correctly' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_number='#{from_number}',origination_caller_id_name='#{from_name}'}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with a name and empty channel in the from field' do
            let(:from_name)   { 'Jane Smith' }
            let(:from_number) { '' }
            let(:from)        { "#{from_name} <#{from_number}>" }

            it 'sends an originate bgapi command with the cid fields set correctly' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_name='#{from_name}'}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with a number in the from field with angled brackets' do
            let(:from_number) { '1001' }
            let(:from)        { "<#{from_number}>" }

            it 'sends an originate bgapi command with the cid fields set correctly' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_number='#{from_number}'}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with an empty from attribute' do
            let(:from) { '' }

            it 'sends an originate bgapi command with the cid fields set correctly' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id}}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with no from attribute' do
            let(:from) { nil }

            it 'sends an originate bgapi command with the cid fields set correctly' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id}}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with a timeout specified' do
            let :dial_command_options do
              { :timeout => 10000 }
            end

            it 'includes the timeout in the originate command' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_number='#{from}',originate_timeout=10}#{to} &park()"
              subject.dial dial_command
            end
          end

          context 'with headers specified' do
            let :dial_command_options do
              { :headers => {'X-foo' => 'bar', 'X-doo' => 'dah'} }
            end

            it 'includes the headers in the originate command' do
              stream.should_receive(:bgapi).once.with "originate {return_ring_ready=true,origination_uuid=#{subject.id},origination_caller_id_number='#{from}',sip_h_X-foo='bar',sip_h_X-doo='dah'}#{to} &park()"
              subject.dial dial_command
            end
          end

          it 'sends the call ID as a response to the Dial' do
            subject.dial dial_command
            dial_command.response
            dial_command.target_call_id.should be == subject.id
          end

          it 'should make the call identify as outbound' do
            subject.dial dial_command
            subject.direction.should be == :outbound
            subject.outbound?.should be true
            subject.inbound?.should be false
          end
        end

        describe '#handle_es_event' do
          context 'with a CHANNEL_HANGUP event' do
            let :es_event do
              RubyFS::Event.new nil, :event_name        => "CHANNEL_HANGUP",
                :hangup_cause                           => cause,
                :channel_state                          => "CS_HANGUP",
                :channel_call_state                     => "HANGUP",
                :channel_state_number                   => "10",
                :unique_id                              => "756bdd8e-c064-11e1-b0ac-fffeda3ce54f",
                :answer_state                           => "hangup",
                :variable_sip_term_status               => "487",
                :variable_proto_specific_hangup_cause   => "sip%3A487",
                :variable_sip_term_cause                => "487"
            end

            let(:cause) { 'ORIGINATOR_CANCEL' }

            it "should cause the actor to be terminated" do
              translator.should_receive(:handle_pb_event).once
              subject.handle_es_event es_event
              sleep 0.25
              subject.should_not be_alive
            end

            it "de-registers the call from the translator" do
              translator.stub :handle_pb_event
              translator.should_receive(:deregister_call).once.with(subject)
              subject.handle_es_event es_event
            end

            it "should cause all components to send complete events before sending end event" do
              ssml_doc = RubySpeech::SSML.draw { audio { 'foo.wav' } }
              comp_command = Punchblock::Component::Output.new :render_document => {:value => ssml_doc}
              comp_command.request!
              component = subject.execute_command comp_command
              comp_command.response(0.1).should be_a Ref

              expected_complete_event = Punchblock::Event::Complete.new :target_call_id => subject.id, :component_id => component.id
              expected_complete_event.reason = Punchblock::Event::Complete::Hangup.new
              expected_end_event = Punchblock::Event::End.new :reason => :hangup, :target_call_id  => subject.id

              translator.should_receive(:handle_pb_event).with(expected_complete_event).once.ordered
              translator.should_receive(:handle_pb_event).with(expected_end_event).once.ordered
              subject.handle_es_event es_event
            end

            [
              'NORMAL_CLEARING',
              'ORIGINATOR_CANCEL',
              'SYSTEM_SHUTDOWN',
              'BLIND_TRANSFER',
              'ATTENDED_TRANSFER',
              'PICKED_OFF',
              'NORMAL_UNSPECIFIED'
            ].each do |cause|
              context "with a #{cause} cause" do
                let(:cause) { cause }

                it 'should send an end (hangup) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason         => :hangup,
                                                                  :target_call_id => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end

            context "with a MANAGER_REQUEST cause" do
              let(:cause) { 'MANAGER_REQUEST' }

              it 'should send an end (hangup-command) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason         => :hangup_command,
                                                                :target_call_id => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.handle_es_event es_event
              end
            end

            context "with a user busy cause" do
              let(:cause) { 'USER_BUSY' }

              it 'should send an end (busy) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason         => :busy,
                                                                :target_call_id => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.handle_es_event es_event
              end
            end

            [
              'NO_USER_RESPONSE',
              'NO_ANSWER',
              'SUBSCRIBER_ABSENT',
              'ALLOTTED_TIMEOUT',
              'MEDIA_TIMEOUT',
              'PROGRESS_TIMEOUT'
            ].each do |cause|
              context "with a #{cause} cause" do
                let(:cause) { cause }

                it 'should send an end (timeout) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason         => :timeout,
                                                                  :target_call_id => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end

            [
              'CALL_REJECTED',
              'NUMBER_CHANGED',
              'REDIRECTION_TO_NEW_DESTINATION',
              'FACILITY_REJECTED',
              'NORMAL_CIRCUIT_CONGESTION',
              'SWITCH_CONGESTION',
              'USER_NOT_REGISTERED',
              'FACILITY_NOT_SUBSCRIBED',
              'OUTGOING_CALL_BARRED',
              'INCOMING_CALL_BARRED',
              'BEARERCAPABILITY_NOTAUTH',
              'BEARERCAPABILITY_NOTAVAIL',
              'SERVICE_UNAVAILABLE',
              'BEARERCAPABILITY_NOTIMPL',
              'CHAN_NOT_IMPLEMENTED',
              'FACILITY_NOT_IMPLEMENTED',
              'SERVICE_NOT_IMPLEMENTED'
            ].each do |cause|
              context "with a #{cause} cause" do
                let(:cause) { cause }

                it 'should send an end (reject) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason         => :reject,
                                                                  :target_call_id => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end

            [
              "UNSPECIFIED",
              "UNALLOCATED_NUMBER",
              "NO_ROUTE_TRANSIT_NET",
              "NO_ROUTE_DESTINATION",
              "CHANNEL_UNACCEPTABLE",
              "CALL_AWARDED_DELIVERED",
              "EXCHANGE_ROUTING_ERROR",
              "DESTINATION_OUT_OF_ORDER",
              "INVALID_NUMBER_FORMAT",
              "RESPONSE_TO_STATUS_ENQUIRY",
              "NETWORK_OUT_OF_ORDER",
              "NORMAL_TEMPORARY_FAILURE",
              "ACCESS_INFO_DISCARDED",
              "REQUESTED_CHAN_UNAVAIL",
              "PRE_EMPTED",
              "INVALID_CALL_REFERENCE",
              "INCOMPATIBLE_DESTINATION",
              "INVALID_MSG_UNSPECIFIED",
              "MESSAGE_TYPE_NONEXIST",
              "WRONG_MESSAGE",
              "IE_NONEXIST",
              "INVALID_IE_CONTENTS",
              "WRONG_CALL_STATE",
              "RECOVERY_ON_TIMER_EXPIRE",
              "MANDATORY_IE_LENGTH_ERROR",
              "PROTOCOL_ERROR",
              "INTERWORKING",
              "CRASH",
              "LOSE_RACE",
              "USER_CHALLENGE"
            ].each do |cause|
              context "with a #{cause} cause" do
                let(:cause) { cause }

                it 'should send an end (error) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason         => :error,
                                                                  :target_call_id => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end
          end

          context 'with an event for a known component' do
            let(:mock_component_node) { mock 'Punchblock::Component::Output' }
            let :component do
              Component::Output.new mock_component_node, subject
            end

            let(:es_event) do
              RubyFS::Event.new nil, :scope_variable_punchblock_component_id => component.id
            end

            before do
              subject.register_component component
            end

            it 'should send the event to the component' do
              component.should_receive(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end
          end

          context 'with a CHANNEL_STATE event' do
            let :es_event do
              RubyFS::Event.new nil, {
                :event_name         => 'CHANNEL_STATE',
                :channel_call_state => channel_call_state
              }
            end

            context 'ringing' do
              let(:channel_call_state) { 'RINGING' }

              it 'should send a ringing event' do
                expected_ringing = Punchblock::Event::Ringing.new
                expected_ringing.target_call_id = subject.id
                translator.should_receive(:handle_pb_event).with expected_ringing
                subject.handle_es_event es_event
              end

              it '#answered? should return false' do
                subject.handle_es_event es_event
                subject.should_not be_answered
              end
            end

            context 'something else' do
              let(:channel_call_state) { 'FOO' }

              it 'should not send a ringing event' do
                translator.should_receive(:handle_pb_event).never
                subject.handle_es_event es_event
              end

              it '#answered? should return false' do
                subject.handle_es_event es_event
                subject.should_not be_answered
              end
            end
          end

          context 'with a CHANNEL_ANSWER event' do
            let :es_event do
              RubyFS::Event.new nil, :event_name => 'CHANNEL_ANSWER'
            end

            it 'should send an answered event' do
              expected_answered = Punchblock::Event::Answered.new
              expected_answered.target_call_id = subject.id
              translator.should_receive(:handle_pb_event).with expected_answered
              subject.handle_es_event es_event
            end

            it '#answered? should be true' do
              subject.handle_es_event es_event
              subject.should be_answered
            end
          end

          context 'with a handler registered for a matching event' do
            let :es_event do
              RubyFS::Event.new nil, :event_name => 'DTMF'
            end

            let(:response) { mock 'Response' }

            it 'should execute the handler' do
              response.should_receive(:call).once.with es_event
              subject.register_handler :es, :event_name => 'DTMF' do |event|
                response.call event
              end
              subject.handle_es_event es_event
            end
          end

          context 'with a CHANNEL_BRIDGE event' do
            let(:other_call_id) { Punchblock.new_uuid }

            let :expected_joined do
              Punchblock::Event::Joined.new.tap do |joined|
                joined.target_call_id = subject.id
                joined.call_uri = other_call_id
              end
            end

            context "where this is the joining call" do
              let :bridge_event do
                RubyFS::Event.new nil, {
                  :unique_id            => id,
                  :event_name           => 'CHANNEL_BRIDGE',
                  :other_leg_unique_id  => other_call_id
                }
              end

              it "should send a joined event with the correct call ID" do
                translator.should_receive(:handle_pb_event).with expected_joined
                subject.handle_es_event bridge_event
              end
            end

            context "where this is the joined call" do
              let :bridge_event do
                RubyFS::Event.new nil, {
                  :unique_id            => other_call_id,
                  :event_name           => 'CHANNEL_BRIDGE',
                  :other_leg_unique_id  => id
                }
              end

              it "should send a joined event with the correct call ID" do
                translator.should_receive(:handle_pb_event).with expected_joined
                subject.handle_es_event bridge_event
              end
            end
          end

          context 'with a CHANNEL_UNBRIDGE event' do
            let(:other_call_id) { Punchblock.new_uuid }

            let :expected_unjoined do
              Punchblock::Event::Unjoined.new.tap do |joined|
                joined.target_call_id = subject.id
                joined.call_uri = other_call_id
              end
            end

            context "where this is the unjoining call" do
              let :unbridge_event do
                RubyFS::Event.new nil, {
                  :unique_id            => id,
                  :event_name           => 'CHANNEL_UNBRIDGE',
                  :other_leg_unique_id  => other_call_id
                }
              end

              it "should send a unjoined event with the correct call ID" do
                translator.should_receive(:handle_pb_event).with expected_unjoined
                subject.handle_es_event unbridge_event
              end
            end

            context "where this is the joined call" do
              let :unbridge_event do
                RubyFS::Event.new nil, {
                  :unique_id            => other_call_id,
                  :event_name           => 'CHANNEL_UNBRIDGE',
                  :other_leg_unique_id  => id
                }
              end

              it "should send a unjoined event with the correct call ID" do
                translator.should_receive(:handle_pb_event).with expected_unjoined
                subject.handle_es_event unbridge_event
              end
            end
          end
        end

        describe '#execute_command' do
          before do
            command.request!
          end

          context 'with an accept command' do
            let(:command) { Command::Accept.new }

            it "should send a respond 180 command and set the command's response" do
              subject.wrapped_object.should_receive(:application).once.with('respond', '180 Ringing')
              subject.execute_command command
              command.response(0.5).should be true
            end
          end

          context 'with an answer command' do
            let(:command) { Command::Answer.new }

            it "should execute the answer application and set the command's response" do
              subject
              Punchblock.should_receive(:new_uuid).once.and_return 'abc123'
              subject.wrapped_object.should_receive(:application).once.with('answer', "%[punchblock_command_id=abc123]")
              subject.should_not be_answered
              subject.execute_command command
              subject.handle_es_event RubyFS::Event.new(nil, :event_name => 'CHANNEL_ANSWER', :scope_variable_punchblock_command_id => 'abc123')
              command.response(0.5).should be true
              subject.should be_answered
            end

            it "should not execute the answer application twice if already answered" do
              subject
              Punchblock.should_receive(:new_uuid).once.and_return 'abc123'
              subject.wrapped_object.should_receive(:application).once.with('answer', "%[punchblock_command_id=abc123]")
              subject.should_not be_answered
              subject.execute_command command
              subject.handle_es_event RubyFS::Event.new(nil, :event_name => 'CHANNEL_ANSWER', :scope_variable_punchblock_command_id => 'abc123')
              command.response(0.5).should be true
              subject.should be_answered
              subject.execute_command command
            end

            context "when a component has previously been executed" do
              it "should set the answer command's response correctly" do
                subject
                Punchblock.should_receive(:new_uuid).once.and_return 'abc123'
                subject.wrapped_object.should_receive(:application).once.with('answer', "%[punchblock_command_id=abc123]")
                subject.should_not be_answered
                subject.execute_command command
                subject.handle_es_event RubyFS::Event.new(nil, :event_name => 'CHANNEL_ANSWER', :scope_variable_punchblock_command_id => 'abc123', :scope_variable_punchblock_component_id => 'dj182989j')
                command.response(0.5).should be true
                subject.should be_answered
              end
            end
          end

          def expect_hangup_with_reason(reason)
            subject.wrapped_object.should_receive(:sendmsg).once.with(:call_command => 'hangup', :hangup_cause => reason)
          end

          context 'with a hangup command' do
            let(:command) { Command::Hangup.new }

            it "should send a hangup message and set the command's response" do
              expect_hangup_with_reason 'MANAGER_REQUEST'
              subject.execute_command command
              command.response(0.5).should be true
            end
          end

          context 'with a reject command' do
            let(:command) { Command::Reject.new }

            it "with a :busy reason should send a USER_BUSY hangup command and set the command's response" do
              command.reason = :busy
              expect_hangup_with_reason 'USER_BUSY'
              subject.execute_command command
              command.response(0.5).should be true
            end

            it "with a :decline reason should send a CALL_REJECTED hangup command and set the command's response" do
              command.reason = :decline
              expect_hangup_with_reason 'CALL_REJECTED'
              subject.execute_command command
              command.response(0.5).should be true
            end

            it "with an :error reason should send a NORMAL_TEMPORARY_FAILURE hangup command and set the command's response" do
              command.reason = :error
              expect_hangup_with_reason 'NORMAL_TEMPORARY_FAILURE'
              subject.execute_command command
              command.response(0.5).should be true
            end
          end

          context 'with an Output component' do
            let :command do
              Punchblock::Component::Output.new
            end

            let(:mock_component) { Translator::Freeswitch::Component::Output.new(command, subject) }

            ['freeswitch', nil].each do |media_engine|
              let(:media_engine) { media_engine }

              context "with a media engine of #{media_engine}" do
                it 'should create an Output component and execute it asynchronously' do
                  Component::Output.should_receive(:new_link).once.with(command, subject).and_return mock_component
                  mock_component.should_receive(:execute).once
                  subject.execute_command command
                  subject.component_with_id(mock_component.id).should be mock_component
                end
              end
            end

            context 'with the media engine of :flite' do
              let(:media_engine) { :flite }

              it 'should create a FliteOutput component and execute it asynchronously using flite and the calls default voice' do
                Component::FliteOutput.should_receive(:new_link).once.with(command, subject).and_return mock_component
                mock_component.should_receive(:execute).once.with(media_engine, default_voice)
                subject.execute_command command
                subject.component_with_id(mock_component.id).should be mock_component
              end
            end

            context 'with the media engine of :cepstral' do
              let(:media_engine) { :cepstral }

              it 'should create a TTSOutput component and execute it asynchronously using cepstral and the calls default voice' do
                Component::TTSOutput.should_receive(:new_link).once.with(command, subject).and_return mock_component
                mock_component.should_receive(:execute).once.with(media_engine, default_voice)
                subject.execute_command command
                subject.component_with_id(mock_component.id).should be mock_component
              end
            end

            context 'with the media engine of :unimrcp' do
              let(:media_engine) { :unimrcp }

              it 'should create a TTSOutput component and execute it asynchronously using unimrcp and the calls default voice' do
                Component::TTSOutput.should_receive(:new_link).once.with(command, subject).and_return mock_component
                mock_component.should_receive(:execute).once.with(media_engine, default_voice)
                subject.execute_command command
                subject.component_with_id(mock_component.id).should be mock_component
              end
            end

            context "with a media renderer set on the component" do
              let(:media_engine) { :cepstral }
              let(:media_renderer) { :native }
              let :command_with_renderer do
                Punchblock::Component::Output.new :renderer => media_renderer
              end

              it "should use the component media engine and not the platform one if it is set" do
                Component::Output.should_receive(:new_link).once.with(command_with_renderer, subject).and_return mock_component
                mock_component.should_receive(:execute).once
                subject.execute_command command_with_renderer
                subject.component_with_id(mock_component.id).should be mock_component
              end
            end
          end

          context 'with an Input component' do
            let :command do
              Punchblock::Component::Input.new
            end

            let(:mock_component) { Translator::Freeswitch::Component::Input.new(command, subject) }

            it 'should create an Input component and execute it asynchronously' do
              Component::Input.should_receive(:new_link).once.with(command, subject).and_return mock_component
              mock_component.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a Record component' do
            let :command do
              Punchblock::Component::Record.new
            end

            let(:mock_component) { Translator::Freeswitch::Component::Record.new(command, subject) }

            it 'should create a Record component and execute it asynchronously' do
              Component::Record.should_receive(:new_link).once.with(command, subject).and_return mock_component
              mock_component.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a component command' do
            let(:component_id) { 'foobar' }

            let :command do
              Punchblock::Component::Stop.new :component_id => component_id
            end

            let :mock_component do
              mock 'Component', :id => component_id
            end

            context "for a known component ID" do
              before { subject.register_component mock_component }

              it 'should send the command to the component for execution' do
                mock_component.should_receive(:execute_command).once
                subject.execute_command command
              end
            end

            context "for a component which began executing but crashed" do
              let :component_command do
                Punchblock::Component::Output.new :render_document => {:value => RubySpeech::SSML.draw}
              end

              let(:comp_id) { component_command.response.uri }

              let(:subsequent_command) { Punchblock::Component::Stop.new :component_id => comp_id }

              let :expected_event do
                Punchblock::Event::Complete.new.tap do |e|
                  e.target_call_id = subject.id
                  e.component_id = comp_id
                  e.reason = Punchblock::Event::Complete::Error.new
                end
              end

              before do
                component_command.request!
                subject.execute_command component_command
              end

              it 'sends an error in response to the command' do
                component = subject.component_with_id comp_id

                component.wrapped_object.define_singleton_method(:oops) do
                  raise 'Woops, I died'
                end

                translator.should_receive(:handle_pb_event).once.with expected_event

                lambda { component.oops }.should raise_error(/Woops, I died/)
                sleep 0.1
                component.should_not be_alive
                subject.component_with_id(comp_id).should be_nil

                subsequent_command.request!
                subject.execute_command subsequent_command
                subsequent_command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{comp_id} for call #{subject.id}", subject.id, comp_id)
              end
            end

            context "for an unknown component ID" do
              it 'sends an error in response to the command' do
                subject.execute_command command
                command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{component_id} for call #{subject.id}", subject.id, component_id)
              end
            end
          end

          context 'with a command we do not understand' do
            let :command do
              Punchblock::Command::Mute.new
            end

            it 'sends an error in response to the command' do
              subject.execute_command command
              command.response.should be == ProtocolError.new.setup('command-not-acceptable', "Did not understand command for call #{subject.id}", subject.id)
            end
          end

          context "with a join command" do
            let(:other_call_id) { Punchblock.new_uuid }

            let :command do
              Punchblock::Command::Join.new :call_uri => other_call_id
            end

            it "executes the proper uuid_bridge command" do
              subject.wrapped_object.should_receive(:uuid_foo).once.with :bridge, other_call_id
              subject.execute_command command
              expect { command.response 1 }.to raise_exception(Timeout::Error)
            end

            context "subsequently receiving a CHANNEL_BRIDGE event" do
              let :bridge_event do
                RubyFS::Event.new nil, {
                  :event_name           => 'CHANNEL_BRIDGE',
                  :other_leg_unique_id  => other_call_id
                }
              end

              before do
                subject.execute_command command
              end

              it "should set the command response to true" do
                subject.handle_es_event bridge_event
                command.response.should be_true
              end
            end
          end

          context "with an unjoin command" do
            let(:other_call_id) { Punchblock.new_uuid }

            let :command do
              Punchblock::Command::Unjoin.new :call_uri => other_call_id
            end

            it "executes the unjoin via transfer to park" do
              subject.wrapped_object.should_receive(:uuid_foo).once.with :transfer, '-both park inline'
              subject.execute_command command
              expect { command.response 1 }.to raise_exception(Timeout::Error)
            end

            context "subsequently receiving a CHANNEL_UNBRIDGE event" do
              let :unbridge_event do
                RubyFS::Event.new nil, {
                  :event_name           => 'CHANNEL_UNBRIDGE',
                  :other_leg_unique_id  => other_call_id
                }
              end

              before do
                subject.execute_command command
              end

              it "should set the command response to true" do
                subject.handle_es_event unbridge_event
                command.response.should be_true
              end
            end
          end
        end
      end
    end
  end
end
