# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    describe Freeswitch do
      let(:connection) { mock 'Connection::Freeswitch' }

      let(:translator) { described_class.new connection }

      before { connection.expects(:stream).times(0..1).returns :foo }

      subject { translator }

      its(:connection)  { should be connection }
      its(:stream)      { should be :foo }

      describe '#shutdown' do
        it "instructs all calls to shutdown" do
          call = described_class::Call.new 'foo', subject
          call.expects(:shutdown).once
          subject.register_call call
          subject.shutdown
        end

        it "terminates the actor" do
          subject.shutdown
          subject.should_not be_alive
        end
      end

      describe '#execute_command' do
        describe 'with a call command' do
          let(:command) { Command::Answer.new }
          let(:call_id) { 'abc123' }

          it 'executes the call command' do
            subject.wrapped_object.expects(:execute_call_command).with do |c|
              c.should be command
              c.target_call_id.should be == call_id
            end
            subject.execute_command command, :call_id  =>  call_id
          end
        end

        describe 'with a global component command' do
          let(:command)       { Component::Stop.new }
          let(:component_id)  { '123abc' }

          it 'executes the component command' do
            subject.wrapped_object.expects(:execute_component_command).with do |c|
              c.should be command
              c.component_id.should be == component_id
            end
            subject.execute_command command, :component_id  =>  component_id
          end
        end

        describe 'with a global command' do
          let(:command) { Command::Dial.new }

          it 'executes the command directly' do
            subject.wrapped_object.expects(:execute_global_command).with command
            subject.execute_command command
          end
        end
      end

      describe '#register_call' do
        let(:call_id)     { 'abc123' }
        let(:platform_id) { '123abc' }
        let(:call)        { described_class::Call.new platform_id, subject }

        before do
          call.stubs(:id).returns call_id
          subject.register_call call
        end

        it 'should make the call accessible by ID' do
          subject.call_with_id(call_id).should be call
        end

        it 'should make the call accessible by platform_id' do
          subject.call_for_platform_id(platform_id).should be call
        end
      end

      describe '#deregister_call' do
        let(:call_id)     { 'abc123' }
        let(:platform_id) { '123abc' }
        let(:call)        { described_class::Call.new platform_id, subject }

        before do
          call.stubs(:id).returns call_id
          subject.register_call call
        end

        it 'should make the call inaccessible by ID' do
          subject.call_with_id(call_id).should be call
          subject.deregister_call call
          subject.call_with_id(call_id).should be_nil
        end

        it 'should make the call inaccessible by platform_id' do
          subject.call_for_platform_id(platform_id).should be call
          subject.deregister_call call
          subject.call_for_platform_id(platform_id).should be_nil
        end
      end

      describe '#register_component' do
        let(:component_id) { 'abc123' }
        let(:component)    { mock 'Foo', :id => component_id }

        it 'should make the component accessible by ID' do
          subject.register_component component
          subject.component_with_id(component_id).should be component
        end
      end

      describe '#execute_call_command' do
        let(:call_id) { 'abc123' }
        let(:call)    { described_class::Call.new 'foo', subject }
        let(:command) { Command::Answer.new.tap { |c| c.target_call_id = call_id } }

        before do
          command.request!
          call.stubs(:id).returns call_id
        end

        context "with a known call ID" do
          before do
            subject.register_call call
          end

          it 'sends the command to the call for execution' do
            call.expects(:execute_command!).once.with command
            subject.execute_call_command command
          end
        end

        context "with an unknown call ID" do
          it 'sends an error in response to the command' do
            subject.execute_call_command command
            command.response.should be == ProtocolError.new.setup('item-not-found', "Could not find a call with ID #{call_id}", call_id, nil)
          end
        end
      end

      describe '#execute_component_command' do
        let(:component_id)  { '123abc' }
        let(:component)     { mock 'Translator::Freeswitch::Component', :id => component_id }

        let(:command) { Component::Stop.new.tap { |c| c.component_id = component_id } }

        before do
          command.request!
        end

        context 'with a known component ID' do
          before do
            subject.register_component component
          end

          it 'sends the command to the component for execution' do
            component.expects(:execute_command!).once.with command
            subject.execute_component_command command
          end
        end

        context "with an unknown component ID" do
          it 'sends an error in response to the command' do
            subject.execute_component_command command
            command.response.should be == ProtocolError.new.setup('item-not-found', "Could not find a component with ID #{component_id}", nil, component_id)
          end
        end
      end

      describe '#execute_global_command' do
        context 'with a Dial' do
          let :command do
            Command::Dial.new :to => '1234', :from => 'abc123'
          end

          before do
            command.request!
            # ami_client.stub_everything
          end

          it 'should be able to look up the call by channel ID' do
            subject.execute_global_command command
            call_actor = subject.call_for_platform_id('1234')
            call_actor.should be_a Freeswitch::Call
          end

          it 'should instruct the call to send a dial' do
            mock_call = stub_everything 'Freeswitch::Call'
            Freeswitch::Call.expects(:new).once.returns mock_call
            mock_call.expects(:dial!).once.with command
            subject.execute_global_command command
          end
        end

      #   context 'with an AMI action' do
      #     let :command do
      #       Component::Asterisk::AMI::Action.new :name  =>  'Status', :params  =>  { :channel  =>  'foo' }
      #     end

      #     let(:mock_action) { stub_everything 'Asterisk::Component::Asterisk::AMIAction' }

      #     it 'should create a component actor and execute it asynchronously' do
      #       Asterisk::Component::Asterisk::AMIAction.expects(:new).once.with(command, subject).returns mock_action
      #       mock_action.expects(:execute!).once
      #       subject.execute_global_command command
      #     end

      #     it 'registers the component' do
      #       Asterisk::Component::Asterisk::AMIAction.expects(:new).once.with(command, subject).returns mock_action
      #       subject.wrapped_object.expects(:register_component).with mock_action
      #       subject.execute_global_command command
      #     end
      #   end

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
          event = mock 'Punchblock::Event'
          subject.connection.expects(:handle_event).once.with event
          subject.handle_pb_event event
        end
      end

      describe '#handle_es_event' do
      #   let :expected_pb_event do
      #     Event::Asterisk::AMI::Event.new :name  =>  'Newchannel',
      #                                     :attributes  =>  { :channel   =>  "SIP/101-3f3f",
      #                                                      :state     =>  "Ring",
      #                                                      :callerid  =>  "101",
      #                                                      :uniqueid  =>  "1094154427.10"}
      #   end

      #   it 'should create a Punchblock AMI event object and pass it to the connection' do
      #     subject.connection.expects(:handle_event).once.with expected_pb_event
      #     subject.handle_ami_event ami_event
      #   end

        before { subject.wrapped_object.stubs :handle_pb_event }

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

        it 'should be able to look up the call by platform ID' do
          subject.handle_es_event es_event
          call_actor = subject.call_for_platform_id unique_id
          call_actor.should be_a Freeswitch::Call
          call_actor.es_env.should be ==  {
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
            subject.wrapped_object.expects(:handle_pb_event).once.with(Punchblock::Connection::Connected.new)
            subject.handle_es_event es_event
          end
        end

        describe 'with a CHANNEL_PARK event' do
          it 'should instruct the call to send an offer' do
            mock_call = stub_everything 'Freeswitch::Call'
            Freeswitch::Call.expects(:new).once.returns mock_call
            mock_call.expects(:send_offer!).once
            subject.handle_es_event es_event
          end

          context 'if a call already exists for a matching platform ID' do
            let(:call) { Freeswitch::Call.new unique_id, subject }

            before do
              subject.register_call call
            end

            it "should not create a new call" do
              Freeswitch::Call.expects(:new).never
              subject.handle_es_event es_event
            end
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
            call.expects(:handle_es_event!).once.with es_event
            subject.handle_es_event es_event
          end
        end
      end
    end
  end
end
