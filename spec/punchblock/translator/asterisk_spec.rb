# encoding: utf-8

require 'spec_helper'
require 'ostruct'

module Punchblock
  module Translator
    describe Asterisk do
      let(:ami_client)    { double 'RubyAMI::Client' }
      let(:connection)    { double 'Connection::Asterisk', handle_event: nil }
      let(:media_engine)  { :asterisk }

      let(:translator) { Asterisk.new ami_client, connection, media_engine }

      subject { translator }

      its(:ami_client) { should be ami_client }
      its(:connection) { should be connection }

      after { translator.terminate if translator.alive? }

      context 'with a configured media engine of :asterisk' do
        let(:media_engine) { :asterisk }
        its(:media_engine) { should be == :asterisk }
      end

      context 'with a configured media engine of :unimrcp' do
        let(:media_engine) { :unimrcp }
        its(:media_engine) { should be == :unimrcp }
      end

      describe '#shutdown' do
        it "instructs all calls to shutdown" do
          call = Asterisk::Call.new 'foo', subject, ami_client, connection
          call.async.should_receive(:shutdown).once
          subject.register_call call
          subject.shutdown
        end

        it "terminates the actor" do
          subject.shutdown
          sleep 0.2
          subject.should_not be_alive
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
        let(:channel) { 'SIP/foo' }
        let(:call)    { Translator::Asterisk::Call.new channel, subject, ami_client, connection }

        before do
          call.stub(:id).and_return call_id
          subject.register_call call
        end

        it 'should make the call accessible by ID' do
          subject.call_with_id(call_id).should be call
        end

        it 'should make the call accessible by channel' do
          subject.call_for_channel(channel).should be call
        end
      end

      describe '#deregister_call' do
        let(:call_id) { 'abc123' }
        let(:channel) { 'SIP/foo' }
        let(:call)    { Translator::Asterisk::Call.new channel, subject, ami_client, connection }

        before do
          call.stub(:id).and_return call_id
          subject.register_call call
        end

        it 'should make the call inaccessible by ID' do
          subject.call_with_id(call_id).should be call
          subject.deregister_call call_id, channel
          subject.call_with_id(call_id).should be_nil
        end

        it 'should make the call inaccessible by channel' do
          subject.call_for_channel(channel).should be call
          subject.deregister_call call_id, channel
          subject.call_for_channel(channel).should be_nil
        end
      end

      describe '#register_component' do
        let(:component_id) { 'abc123' }
        let(:component)    { double 'Asterisk::Component::Asterisk::AMIAction', :id => component_id }

        it 'should make the component accessible by ID' do
          subject.register_component component
          subject.component_with_id(component_id).should be component
        end
      end

      describe '#execute_call_command' do
        let(:call_id) { 'abc123' }
        let(:command) { Command::Answer.new target_call_id: call_id }

        context "with a known call ID" do
          let(:call) { Translator::Asterisk::Call.new 'SIP/foo', subject, ami_client, connection }

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
            subject.async.should_receive(:execute_global_command)
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
          let :ami_event do
            RubyAMI::Event.new 'AsyncAGI',
              'SubEvent' => "Start",
              'Channel'  => "SIP/1234-00000000",
              'Env'      => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          let(:call)    { subject.call_for_channel('SIP/1234-00000000') }
          let(:call_id) { call.id }

          before do
            connection.stub :handle_event
            subject.handle_ami_event ami_event
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
        let(:call)            { Translator::Asterisk::Call.new 'SIP/foo', subject, ami_client, connection }
        let(:component_node)  { Component::Output.new }
        let(:component)       { Translator::Asterisk::Component::Output.new(component_node, call) }

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
            Command::Dial.new :to => 'SIP/1234', :from => 'abc123'
          end

          before do
            command.request!
            ami_client.stub(:send_action).and_return RubyAMI::Response.new
          end

          it 'should be able to look up the call by channel ID' do
            subject.execute_global_command command
            call_actor = subject.call_for_channel('SIP/1234')
            call_actor.wrapped_object.should be_a Asterisk::Call
          end

          it 'should instruct the call to send a dial' do
            mock_call = double('Asterisk::Call').as_null_object
            Asterisk::Call.should_receive(:new_link).once.and_return mock_call
            mock_call.async.should_receive(:dial).once.with command
            subject.execute_global_command command
          end
        end

        context 'with an AMI action' do
          let :command do
            Component::Asterisk::AMI::Action.new :name => 'Status', :params => { :channel => 'foo' }
          end

          let(:mock_action) { double('Asterisk::Component::Asterisk::AMIAction').as_null_object }

          it 'should create a component actor and execute it asynchronously' do
            Asterisk::Component::Asterisk::AMIAction.should_receive(:new).once.with(command, subject, ami_client).and_return mock_action
            mock_action.async.should_receive(:execute).once
            subject.execute_global_command command
          end

          it 'registers the component' do
            Asterisk::Component::Asterisk::AMIAction.should_receive(:new).once.with(command, subject, ami_client).and_return mock_action
            subject.wrapped_object.should_receive(:register_component).with mock_action
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

      describe '#handle_ami_event' do
        let :ami_event do
          RubyAMI::Event.new 'Newchannel',
            'Channel'  => "SIP/101-3f3f",
            'State'    => "Ring",
            'Callerid' => "101",
            'Uniqueid' => "1094154427.10"
        end

        let :expected_pb_event do
          Event::Asterisk::AMI::Event.new name: 'Newchannel',
                                          headers: { 'Channel'  => "SIP/101-3f3f",
                                                     'State'    => "Ring",
                                                     'Callerid' => "101",
                                                     'Uniqueid' => "1094154427.10"}
        end

        it 'should create a Punchblock AMI event object and pass it to the connection' do
          subject.connection.should_receive(:handle_event).once.with expected_pb_event
          subject.handle_ami_event ami_event
        end

        context 'with something that is not a RubyAMI::Event' do
          it 'does not send anything to the connection' do
            subject.connection.should_receive(:handle_event).never
            subject.handle_ami_event :foo
          end
        end

        describe 'with a FullyBooted event' do
          let(:ami_event) { RubyAMI::Event.new 'FullyBooted' }

          it 'sends a connected event to the event handler' do
            subject.connection.should_receive(:handle_event).once.with Connection::Connected.new
            subject.wrapped_object.should_receive(:run_at_fully_booted).once
            subject.handle_ami_event ami_event
          end
        end

        describe 'with an AsyncAGI Start event' do
          let :ami_event do
            RubyAMI::Event.new 'AsyncAGI',
              'SubEvent' => "Start",
              'Channel'  => "SIP/1234-00000000",
              'Env'      => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          before { subject.wrapped_object.stub :handle_pb_event }

          it 'should be able to look up the call by channel ID' do
            subject.handle_ami_event ami_event
            call_actor = subject.call_for_channel('SIP/1234-00000000')
            call_actor.should be_a Asterisk::Call
            call_actor.agi_env.should be_a Hash
            call_actor.agi_env.should be == {
              :agi_request      => 'async',
              :agi_channel      => 'SIP/1234-00000000',
              :agi_language     => 'en',
              :agi_type         => 'SIP',
              :agi_uniqueid     => '1320835995.0',
              :agi_version      => '1.8.4.1',
              :agi_callerid     => '5678',
              :agi_calleridname => 'Jane Smith',
              :agi_callingpres  => '0',
              :agi_callingani2  => '0',
              :agi_callington   => '0',
              :agi_callingtns   => '0',
              :agi_dnid         => '1000',
              :agi_rdnis        => 'unknown',
              :agi_context      => 'default',
              :agi_extension    => '1000',
              :agi_priority     => '1',
              :agi_enhanced     => '0.0',
              :agi_accountcode  => '',
              :agi_threadid     => '4366221312'
            }
          end

          it 'should instruct the call to send an offer' do
            mock_call = double('Asterisk::Call').as_null_object
            Asterisk::Call.should_receive(:new_link).once.and_return mock_call
            mock_call.async.should_receive(:send_offer).once
            subject.handle_ami_event ami_event
          end

          context 'if a call already exists for a matching channel' do
            let(:call) { Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection }

            before do
              subject.register_call call
            end

            it "should not create a new call" do
              Asterisk::Call.should_receive(:new_link).never
              subject.handle_ami_event ami_event
            end
          end

          context "for a 'h' extension" do
            let :ami_event do
              RubyAMI::Event.new 'AsyncAGI',
                'SubEvent' => "Start",
                'Channel'  => "SIP/1234-00000000",
                'Env'      => "agi_extension%3A%20h%0A%0A"
            end

            it "should not create a new call" do
              Asterisk::Call.should_receive(:new).never
              subject.handle_ami_event ami_event
            end

            it 'should not be able to look up the call by channel ID' do
              subject.handle_ami_event ami_event
              subject.call_for_channel('SIP/1234-00000000').should be nil
            end
          end

          context "for a 'Kill' type" do
            let :ami_event do
              RubyAMI::Event.new 'AsyncAGI',
                'SubEvent' => "Start",
                'Channel'  => "SIP/1234-00000000",
                'Env'      => "agi_type%3A%20Kill%0A%0A"
            end

            it "should not create a new call" do
              Asterisk::Call.should_receive(:new).never
              subject.handle_ami_event ami_event
            end

            it 'should not be able to look up the call by channel ID' do
              subject.handle_ami_event ami_event
              subject.call_for_channel('SIP/1234-00000000').should be nil
            end
          end
        end

        describe 'with a VarSet event including a punchblock_call_id' do
          let :ami_event do
            RubyAMI::Event.new 'VarSet',
              "Privilege" => "dialplan,all",
              "Channel"   => "SIP/1234-00000000",
              "Variable"  => "punchblock_call_id",
              "Value"     => call_id,
              "Uniqueid"  => "1326210224.0"
          end

          before do
            ami_client.as_null_object
            subject.wrapped_object.stub :handle_pb_event
          end

          context "matching a call that was created by a Dial command" do
            let(:dial_command) { Punchblock::Command::Dial.new :to => 'SIP/1234', :from => 'abc123' }

            before do
              dial_command.request!
              subject.execute_global_command dial_command
              call
            end

            let(:call)    { subject.call_for_channel 'SIP/1234' }
            let(:call_id) { call.id }

            it "should set the correct channel on the call" do
              subject.handle_ami_event ami_event
              call.channel.should be == 'SIP/1234-00000000'
            end

            it "should make it possible to look up the call by the full channel name" do
              subject.handle_ami_event ami_event
              subject.call_for_channel("SIP/1234-00000000").should be call
            end

            it "should make looking up the channel by the requested channel name impossible" do
              subject.handle_ami_event ami_event
              subject.call_for_channel('SIP/1234').should be_nil
            end
          end

          context "for a call that doesn't exist" do
            let(:call_id) { 'foobarbaz' }

            it "should not raise" do
              lambda { subject.handle_ami_event ami_event }.should_not raise_error
            end
          end
        end

        describe 'with an AMI event for a known channel' do
          let :ami_event do
            RubyAMI::Event.new 'Hangup',
              'Uniqueid'      => "1320842458.8",
              'Calleridnum'   => "5678",
              'Calleridname'  => "Jane Smith",
              'Cause'         => "0",
              'Cause-txt'     => "Unknown",
              'Channel'       => "SIP/1234-00000000"
          end

          let(:call) do
            Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          before do
            subject.register_call call
          end

          it 'sends the AMI event to the call and to the connection as a PB event' do
            call.async.should_receive(:process_ami_event).once.with ami_event
            subject.handle_ami_event ami_event
          end

          context 'with a Channel1 and Channel2 specified on the event' do
            let :ami_event do
              RubyAMI::Event.new 'BridgeAction',
                'Privilege' => "call,all",
                'Response'  => "Success",
                'Channel1'  => "SIP/1234-00000000",
                'Channel2'  => "SIP/5678-00000000"
            end

            context 'with calls for those channels' do
              let(:call2) do
                Asterisk::Call.new "SIP/5678-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before { subject.register_call call2 }

              it 'should send the event to both calls and to the connection once as a PB event' do
                call.async.should_receive(:process_ami_event).once.with ami_event
                call2.async.should_receive(:process_ami_event).once.with ami_event
                subject.handle_ami_event ami_event
              end
            end
          end
        end

        describe 'with an event for a channel with Bridge and special statuses appended' do
          let :ami_event do
            RubyAMI::Event.new 'AGIExec',
              'SubEvent'  => "End",
              'Channel'   => "Bridge/SIP/1234-00000000<ZOMBIE>"
          end

          let :ami_event2 do
            RubyAMI::Event.new 'Hangup',
              'Uniqueid'      => "1320842458.8",
              'Calleridnum'   => "5678",
              'Calleridname'  => "Jane Smith",
              'Cause'         => "0",
              'Cause-txt'     => "Unknown",
              'Channel'       => "Bridge/SIP/1234-00000000<ZOMBIE>"
          end

          let(:call) do
            Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          before do
            subject.register_call call
          end

          it 'sends the AMI event to the call and to the connection as a PB event if it is an allowed event' do
            call.async.should_receive(:process_ami_event).once.with ami_event
            subject.handle_ami_event ami_event
          end

          it 'does not send the AMI event to a bridged channel if it is not allowed' do
            call.async.should_receive(:process_ami_event).never.with ami_event2
            subject.handle_ami_event ami_event2
          end

        end
      end

      describe '#run_at_fully_booted' do
        let(:broken_path) { "/this/is/not/a/valid/path" }

        let(:passed_show) do
          OpenStruct.new text_body: "[ Context 'adhearsion-redirect' created by 'pbx_config' ]\n '1' => 1. AGI(agi:async)[pbx_config]\n\n-= 1 extension (1 priority) in 1 context. =-"
        end

        let(:failed_show) do
          OpenStruct.new text_body: "There is no existence of 'adhearsion-redirect' context\nCommand 'dialplan show adhearsion-redirect' failed."
        end

        it 'should send the redirect extension Command to the AMI client' do
          ami_client.should_receive(:send_action).once.with 'Command', 'Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"
          ami_client.should_receive(:send_action).once.with('Command', 'Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}").and_return(passed_show)
          subject.run_at_fully_booted
        end

        it 'should check the context for existence and do nothing if it is there' do
          ami_client.should_receive(:send_action).once.with 'Command', 'Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"
          ami_client.should_receive(:send_action).once.with('Command', 'Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}").and_return(passed_show)
          subject.run_at_fully_booted
        end

        it 'should check the context for existence and log an error if it is not there' do
          ami_client.should_receive(:send_action).once.with 'Command', 'Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"
          ami_client.should_receive(:send_action).once.with('Command', 'Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}").and_return(failed_show)
          Punchblock.logger.should_receive(:error).once.with("Punchblock failed to add the #{Asterisk::REDIRECT_EXTENSION} extension to the #{Asterisk::REDIRECT_CONTEXT} context. Please add a [#{Asterisk::REDIRECT_CONTEXT}] entry to your dialplan.")
          subject.run_at_fully_booted
        end

        it 'should check the recording directory for existence' do
          stub_const('Punchblock::Translator::Asterisk::Component::Record::RECORDING_BASE_PATH', broken_path)
          ami_client.should_receive(:send_action).once.with 'Command', 'Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"
          ami_client.should_receive(:send_action).once.with('Command', 'Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}").and_return(passed_show)
          Punchblock.logger.should_receive(:warn).once.with("Recordings directory #{broken_path} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording")
          subject.run_at_fully_booted
        end
      end

      describe '#check_recording_directory' do
        let(:broken_path) { "/this/is/not/a/valid/path" }
        it 'logs a warning if the recording directory does not exist' do
          stub_const('Punchblock::Translator::Asterisk::Component::Record::RECORDING_BASE_PATH', broken_path)
          Punchblock.logger.should_receive(:warn).once.with("Recordings directory #{broken_path} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording")
          subject.check_recording_directory
        end
      end
    end
  end
end
