# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      describe Call do
        let(:platform_id) { 'foo' }
        let(:translator)  { stub_everything 'Translator::Freeswitch' }
        let(:stream)      { stub_everything 'RubyFS::Stream' }
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

        subject { Call.new platform_id, translator, es_env, stream }

        its(:id)          { should be_a String }
        its(:platform_id) { should be == platform_id }
        its(:translator)  { should be translator }
        its(:es_env)      { should be == es_env }
        its(:stream)      { should be stream }

        describe '#shutdown' do
          it 'should terminate the actor' do
            subject.shutdown
            sleep 0.5
            subject.should_not be_alive
          end
        end

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
            translator.expects(:handle_pb_event).with expected_offer
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
            stream.expects(:application).once.with(platform_id, 'appname', 'options')
            subject.application 'appname', 'options'
          end
        end

        describe "#sendmsg" do
          it "should execute a FS sendmsg on the current call" do
            stream.expects(:sendmsg).once.with(platform_id, 'msg', :foo => 'bar')
            subject.sendmsg 'msg', :foo => 'bar'
          end
        end

        describe '#dial' do
          let(:dial_command_options) { {} }

          let :dial_command do
            Punchblock::Command::Dial.new({:to => 'SIP/1234', :from => 'sip:foo@bar.com'}.merge(dial_command_options))
          end

          before { dial_command.request! }

        #   it 'sends an Originate AMI action' do
        #     expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
        #                                                                        :params => {
        #                                                                          :async       => true,
        #                                                                          :application => 'AGI',
        #                                                                          :data        => 'agi:async',
        #                                                                          :channel     => 'SIP/1234',
        #                                                                          :callerid    => 'sip:foo@bar.com',
        #                                                                          :variable    => "punchblock_call_id=#{subject.id}"
        #                                                                        }).tap { |a| a.request! }

        #     translator.expects(:execute_global_command!).once.with expected_action
        #     subject.dial dial_command
        #   end

        #   context 'with a timeout specified' do
        #     let :dial_command_options do
        #       { :timeout => 10000 }
        #     end

        #     it 'includes the timeout in the Originate AMI action' do
        #       expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
        #                                                                          :params => {
        #                                                                            :async       => true,
        #                                                                            :application => 'AGI',
        #                                                                            :data        => 'agi:async',
        #                                                                            :channel     => 'SIP/1234',
        #                                                                            :callerid    => 'sip:foo@bar.com',
        #                                                                            :variable    => "punchblock_call_id=#{subject.id}",
        #                                                                            :timeout     => 10000
        #                                                                          }).tap { |a| a.request! }

        #       translator.expects(:execute_global_command!).once.with expected_action
        #       subject.dial dial_command
        #     end
        #   end

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
              RubyFS::Event.new nil, :event_name     => "CHANNEL_HANGUP",
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
              translator.expects(:handle_pb_event).once
              subject.handle_es_event es_event
              sleep 5.5
              subject.should_not be_alive
            end

            it "de-registers the call from the translator" do
              translator.stubs :handle_pb_event
              translator.expects(:deregister_call).once.with(subject)
              subject.handle_es_event es_event
            end

        #     it "should cause all components to send complete events before sending end event" do
        #       comp_command = Punchblock::Component::Input.new :grammar => {:value => '<grammar/>'}, :mode => :dtmf
        #       comp_command.request!
        #       component = subject.execute_command comp_command
        #       comp_command.response(0.1).should be_a Ref
        #       expected_complete_event = Punchblock::Event::Complete.new :target_call_id => subject.id, :component_id => component.id
        #       expected_complete_event.reason = Punchblock::Event::Complete::Hangup.new
        #       expected_end_event = Punchblock::Event::End.new :reason => :hangup, :target_call_id  => subject.id
        #       end_sequence = sequence 'end events'
        #       translator.expects(:handle_pb_event).with(expected_complete_event).once.in_sequence(end_sequence)
        #       translator.expects(:handle_pb_event).with(expected_end_event).once.in_sequence(end_sequence)
        #       subject.process_ami_event ami_event
        #     end

            [
              'NORMAL_CLEARING',
              'ORIGINATOR_CANCEL',
              'SYSTEM_SHUTDOWN',
              'MANAGER_REQUEST',
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
                  translator.expects(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end

            context "with a user busy cause" do
              let(:cause) { 'USER_BUSY' }

              it 'should send an end (busy) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason         => :busy,
                                                                :target_call_id => subject.id
                translator.expects(:handle_pb_event).with expected_end_event
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
                  translator.expects(:handle_pb_event).with expected_end_event
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
                  translator.expects(:handle_pb_event).with expected_end_event
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
                  translator.expects(:handle_pb_event).with expected_end_event
                  subject.handle_es_event es_event
                end
              end
            end
          end

          context 'with an event for a known component' do
            let(:mock_component_node) { mock 'Punchblock::Component::Output' }
            let :component do
              Component::Output.new mock_component_node, subject.translator
            end

            let(:es_event) do
              RubyFS::Event.new nil, :scope_variable_punchblock_component_id => component.id
            end

            before do
              subject.register_component component
            end

            it 'should send the event to the component' do
              component.expects(:handle_es_event).once.with es_event
              subject.handle_es_event es_event
            end
          end

        #   context 'with a Newstate event' do
        #     let :ami_event do
        #       RubyAMI::Event.new('Newstate').tap do |e|
        #         e['Privilege']          = 'call,all'
        #         e['Channel']            = 'SIP/1234-00000000'
        #         e['ChannelState']       = channel_state
        #         e['ChannelStateDesc']   = channel_state_desc
        #         e['CallerIDNum']        = ''
        #         e['CallerIDName']       = ''
        #         e['ConnectedLineNum']   = ''
        #         e['ConnectedLineName']  = ''
        #         e['Uniqueid']           = '1326194671.0'
        #       end
        #     end

        #     context 'ringing' do
        #       let(:channel_state)       { '5' }
        #       let(:channel_state_desc)  { 'Ringing' }

        #       it 'should send a ringing event' do
        #         expected_ringing = Punchblock::Event::Ringing.new
        #         expected_ringing.target_call_id = subject.id
        #         translator.expects(:handle_pb_event).with expected_ringing
        #         subject.process_ami_event ami_event
        #       end

        #       it '#answered? should return false' do
        #         subject.process_ami_event ami_event
        #         subject.answered?.should be_false
        #       end
        #     end

        #     context 'up' do
        #       let(:channel_state)       { '6' }
        #       let(:channel_state_desc)  { 'Up' }

        #       it 'should send a ringing event' do
        #         expected_answered = Punchblock::Event::Answered.new
        #         expected_answered.target_call_id = subject.id
        #         translator.expects(:handle_pb_event).with expected_answered
        #         subject.process_ami_event ami_event
        #       end

        #       it '#answered? should be true' do
        #         subject.process_ami_event ami_event
        #         subject.answered?.should be_true
        #       end
        #     end
        #   end

          context 'with a handler registered for a matching event' do
            let :es_event do
              RubyFS::Event.new nil, :event_name => 'DTMF'
            end

            let(:response) { mock 'Response' }

            it 'should execute the handler' do
              response.expects(:call).once.with es_event
              subject.register_handler :es, :event_name => 'DTMF' do |event|
                response.call event
              end
              subject.handle_es_event es_event
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
              subject.wrapped_object.expects(:application).once.with('respond', '180 Ringing').yields(true)
              subject.execute_command command
              command.response(0.5).should be true
            end
          end

          context 'with an answer command' do
            let(:command) { Command::Answer.new }

            it "should execute the answer application and set the command's response" do
              Punchblock.expects(:new_uuid).once.returns 'abc123'
              subject.wrapped_object.expects(:application).once.with('answer', '%[punchblock_command_id=abc123]')
              subject.execute_command command
              subject.handle_es_event RubyFS::Event.new(nil, :event_name => 'CHANNEL_ANSWER', :scope_variable_punchblock_command_id => 'abc123')
              command.response(0.5).should be true
            end
          end

          def expect_hangup_with_reason(reason)
            subject.wrapped_object.expects(:sendmsg).once.with(:call_command => 'hangup', :hangup_cause => reason).yields(true)
          end

          context 'with a hangup command' do
            let(:command) { Command::Hangup.new }

            it "should send a hangup message and set the command's response" do
              expect_hangup_with_reason 'NORMAL_CLEARING'
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

        #   context 'with an AGI command component' do
        #     let :command do
        #       Punchblock::Component::Asterisk::AGI::Command.new :name => 'Answer'
        #     end

        #     let(:mock_action) { mock 'Component::Asterisk::AGI::Command', :id => 'foo' }

        #     it 'should create an AGI command component actor and execute it asynchronously' do
        #       mock_action.expects(:internal=).never
        #       Component::Asterisk::AGICommand.expects(:new_link).once.with(command, subject).returns mock_action
        #       mock_action.expects(:execute!).once
        #       subject.execute_command command
        #     end
        #   end

          context 'with an Output component' do
            let :command do
              Punchblock::Component::Output.new
            end

            let(:mock_action) { mock 'Component::Asterisk::Output', :id => 'foo' }

            it 'should create an Output component and execute it asynchronously' do
              Component::Output.expects(:new_link).once.with(command, subject).returns mock_action
              mock_action.expects(:execute!).once
              subject.execute_command command
              subject.component_with_id('foo').should be mock_action
            end
          end

        #   context 'with an Input component' do
        #     let :command do
        #       Punchblock::Component::Input.new
        #     end

        #     let(:mock_action) { mock 'Component::Asterisk::Input', :id => 'foo' }

        #     it 'should create an Input component and execute it asynchronously' do
        #       Component::Input.expects(:new_link).once.with(command, subject).returns mock_action
        #       mock_action.expects(:internal=).never
        #       mock_action.expects(:execute!).once
        #       subject.execute_command command
        #     end
        #   end

        #   context 'with a Record component' do
        #     let :command do
        #       Punchblock::Component::Record.new
        #     end

        #     let(:mock_action) { mock 'Component::Asterisk::Record', :id => 'foo' }

        #     it 'should create a Record component and execute it asynchronously' do
        #       Component::Record.expects(:new_link).once.with(command, subject).returns mock_action
        #       mock_action.expects(:internal=).never
        #       mock_action.expects(:execute!).once
        #       subject.execute_command command
        #     end
        #   end

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
                mock_component.expects(:execute_command).once
                subject.execute_command command
              end
            end

            context "for a component which began executing but crashed" do
              let :component_command do
                Punchblock::Component::Output.new :ssml => RubySpeech::SSML.draw
              end

              let(:comp_id) { component_command.response.id }

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

                translator.expects(:handle_pb_event).once.with expected_event

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

        #   context "with a join command" do
        #     let(:other_call_id)     { "abc123" }
        #     let(:other_channel)     { 'SIP/bar' }
        #     let(:other_translator)  { stub_everything 'Translator::Asterisk' }

        #     let :other_call do
        #       Call.new other_channel, other_translator
        #     end

        #     let :command do
        #       Punchblock::Command::Join.new :call_id => other_call_id
        #     end

        #     it "executes the proper dialplan Bridge application" do
        #       translator.expects(:call_with_id).with(other_call_id).returns(other_call)
        #       subject.execute_command command
        #       agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
        #       agi_command.name.should be == "EXEC Bridge"
        #       agi_command.params_array.should be == [other_channel]
        #     end

        #     it "adds the join to the @pending_joins hash" do
        #       translator.expects(:call_with_id).with(other_call_id).returns(other_call)
        #       subject.execute_command command
        #       subject.pending_joins[other_channel].should be command
        #     end
        #   end

        #   context "with an unjoin command" do
        #     let(:other_call_id) { "abc123" }
        #     let(:other_channel) { 'SIP/bar' }

        #     let :other_call do
        #       Call.new other_channel, translator
        #     end

        #     let :command do
        #       Punchblock::Command::Unjoin.new :call_id => other_call_id
        #     end

        #     it "executes the unjoin through redirection" do
        #       translator.expects(:call_with_id).with(other_call_id).returns(nil)
        #       subject.execute_command command
        #       ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
        #       ami_action.name.should be == "redirect"
        #       ami_action.headers['Channel'].should be == channel
        #       ami_action.headers['Exten'].should be == Punchblock::Translator::Freeswitch::REDIRECT_EXTENSION
        #       ami_action.headers['Priority'].should be == Punchblock::Translator::Freeswitch::REDIRECT_PRIORITY
        #       ami_action.headers['Context'].should be == Punchblock::Translator::Freeswitch::REDIRECT_CONTEXT
        #     end

        #     it "executes the unjoin through redirection, on the subject call and the other call" do
        #       translator.expects(:call_with_id).with(other_call_id).returns(other_call)
        #       subject.execute_command command
        #       ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
        #       ami_action.name.should be == "redirect"
        #       ami_action.headers['Channel'].should be == channel
        #       ami_action.headers['Exten'].should be == Punchblock::Translator::Freeswitch::REDIRECT_EXTENSION
        #       ami_action.headers['Priority'].should be == Punchblock::Translator::Freeswitch::REDIRECT_PRIORITY
        #       ami_action.headers['Context'].should be == Punchblock::Translator::Freeswitch::REDIRECT_CONTEXT

        #       ami_action.headers['ExtraChannel'].should be == other_channel
        #       ami_action.headers['ExtraExten'].should be == Punchblock::Translator::Freeswitch::REDIRECT_EXTENSION
        #       ami_action.headers['ExtraPriority'].should be == Punchblock::Translator::Freeswitch::REDIRECT_PRIORITY
        #       ami_action.headers['ExtraContext'].should be == Punchblock::Translator::Freeswitch::REDIRECT_CONTEXT
        #     end
        #   end
        end
      end
    end
  end
end
