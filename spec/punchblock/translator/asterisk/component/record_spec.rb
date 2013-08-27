# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Record do
          include HasMockCallbackConnection

          let(:channel)       { 'SIP/foo' }
          let(:ami_client)    { double('AMI Client').as_null_object }
          let(:translator)    { Punchblock::Translator::Asterisk.new ami_client, connection }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new channel, translator, ami_client, connection }

          let :original_command do
            Punchblock::Component::Record.new command_options
          end

          let :command_options do
            {}
          end

          subject { Record.new original_command, mock_call }

          describe '#execute' do
            let(:reason)    { original_command.complete_event(5).reason }
            let(:recording) { original_command.complete_event(5).recording }

            before { original_command.request! }

            it "returns an error if the call is not answered yet" do
              mock_call.should_receive(:answered?).and_return(false)
              subject.execute
              error = ProtocolError.new.setup 'option error', 'Record cannot be used on a call that is not answered.'
              original_command.response(0.1).should be == error
            end

            before { mock_call.stub(:answered?).and_return(true) }

            it "sets command response to a reference to the component" do
              ami_client.should_receive(:send_action)
              subject.execute
              original_command.response(0.1).should be_a Ref
              original_command.component_id.should be == subject.id
            end

            it "starts a recording via AMI, using the component ID as the filename" do
              filename = "#{Record::RECORDING_BASE_PATH}/#{subject.id}"
              ami_client.should_receive(:send_action).once.with('Monitor', 'Channel' => channel, 'File' => filename, 'Format' => 'wav', 'Mix' => true)
              subject.execute
            end

            it "sends a max duration complete event when the recording ends" do
              full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
              ami_client.should_receive(:send_action)
              subject.execute
              monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
              mock_call.process_ami_event monitor_stop_event
              reason.should be_a Punchblock::Component::Record::Complete::MaxDuration
              recording.uri.should be == full_filename
              original_command.should be_complete
            end

            it "can be called multiple times on the same call" do
              ami_client.should_receive(:send_action).twice
              subject.execute

              monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel

              mock_call.process_ami_event monitor_stop_event

              Record.new(original_command, mock_call).execute
              Punchblock::Component::Record.new(command_options).request!
              mock_call.process_ami_event monitor_stop_event
            end

            describe 'start_paused' do
              context "set to nil" do
                let(:command_options) { { :start_paused => nil } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_paused => false } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  mock_call.should_receive(:execute_agi_command).never
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A start-paused value of true is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'initial_timeout' do
              context "set to nil" do
                let(:command_options) { { :initial_timeout => nil } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :initial_timeout => -1 } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :initial_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  mock_call.should_receive(:execute_agi_command).never
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An initial-timeout value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'final_timeout' do
              context "set to nil" do
                let(:command_options) { { :final_timeout => nil } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :final_timeout => -1 } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :final_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  mock_call.should_receive(:execute_agi_command).never
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A final-timeout value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'format' do
              context "set to nil" do
                let(:command_options) { { :format => nil } }
                it "should execute as 'wav'" do
                  ami_client.should_receive(:send_action).once.with('Monitor', hash_including('Format' => 'wav'))
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  ami_client.should_receive(:send_action)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event
                  recording.uri.should match(/.*\.wav$/)
                end
              end

              context "set to 'mp3'" do
                let(:command_options) { { :format => 'mp3' } }
                it "should execute as 'mp3'" do
                  ami_client.should_receive(:send_action).once.with('Monitor', hash_including('Format' => 'mp3'))
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  ami_client.should_receive(:send_action)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event
                  recording.uri.should match(/.*\.mp3$/)
                end
              end
            end

            describe 'start_beep' do
              context "set to nil" do
                let(:command_options) { { :start_beep => nil } }
                it "should execute normally" do
                  mock_call.should_receive(:execute_agi_command).never.with('STREAM FILE', 'beep', '""')
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_beep => false } }
                it "should execute normally" do
                  mock_call.should_receive(:execute_agi_command).never.with('STREAM FILE', 'beep', '""')
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_beep => true } }

                it "should play a beep before recording" do
                  mock_call.should_receive(:execute_agi_command).once.with('STREAM FILE', 'beep', '""').ordered.and_return code: 200
                  ami_client.should_receive(:send_action).once.ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                context "when we get a RubyAMI Error" do
                  it "should send an error response" do
                    error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                    mock_call.should_receive(:execute_agi_command).and_raise error
                    ami_client.should_receive(:send_action).never
                    subject.execute
                    error = ProtocolError.new.setup :platform_error, "Terminated due to AMI error 'FooBar'"
                    original_command.response(0.1).should be == error
                  end
                end

                context "when the channel is no longer available" do
                  it "should send an error complete event" do
                    mock_call.should_receive(:execute_agi_command).and_raise ChannelGoneError
                    ami_client.should_receive(:send_action).never
                    subject.execute
                    error = ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{mock_call.id}", mock_call.id)
                    original_command.response(0.1).should be == error
                  end
                end
              end
            end

            describe 'max_duration' do
              context "set to nil" do
                let(:command_options) { { :max_duration => nil } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :max_duration => -1 } }
                it "should execute normally" do
                  ami_client.should_receive(:send_action).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context 'a negative number other than -1' do
                let(:command_options) { { :max_duration => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A max-duration value that is negative (and not -1) is invalid.'
                  original_command.response(0.1).should be == error
                end
              end

              context 'a positive number' do
                let(:reason) { original_command.complete_event(5).reason }
                let(:recording) { original_command.complete_event(5).recording }
                let(:command_options) { { :max_duration => 1000 } }

                it "executes a StopMonitor action" do
                  ami_client.should_receive :send_action
                  ami_client.should_receive(:send_action).once.with('StopMonitor', 'Channel' => channel)
                  subject.execute
                  sleep 1.2
                end

                it "sends the correct complete event" do
                  full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                  subject.execute
                  sleep 1.2

                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event

                  reason.should be_a Punchblock::Component::Record::Complete::MaxDuration
                  recording.uri.should be == full_filename
                  original_command.should be_complete
                end
              end
            end
          end

          describe "#execute_command" do
            let(:reason) { original_command.complete_event(5).reason }
            let(:recording) { original_command.complete_event(5).recording }

            context "with a command it does not understand" do
              let(:command) { Punchblock::Component::Output::Pause.new }

              before { command.request! }
              it "returns a ProtocolError response" do
                subject.execute_command command
                command.response(0.1).should be_a ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Punchblock::Component::Stop.new }

              before do
                ami_client.should_receive :send_action
                mock_call.should_receive(:answered?).and_return(true)
                command.request!
                original_command.request!
                subject.execute
              end

              let :send_stop_event do
                monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                mock_call.process_ami_event monitor_stop_event
              end

              it "sets the command response to true" do
                ami_client.should_receive :send_action
                subject.execute_command command
                send_stop_event
                command.response(0.1).should be == true
              end

              it "executes a StopMonitor action" do
                ami_client.should_receive(:send_action).once.with('StopMonitor', 'Channel' => channel)
                subject.execute_command command
              end

              it "sends the correct complete event" do
                ami_client.should_receive(:send_action).and_return RubyAMI::Response.new

                full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                subject.execute_command command
                send_stop_event
                reason.should be_a Punchblock::Event::Complete::Stop
                recording.uri.should be == full_filename
                original_command.should be_complete
              end
            end

            context "with a Pause command" do
              let(:command) { Punchblock::Component::Record::Pause.new }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                ami_client.should_receive(:send_action).and_return RubyAMI::Response.new
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "pauses the recording via AMI" do
                ami_client.should_receive(:send_action).once.with('PauseMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end

            context "with a Resume command" do
              let(:command) { Punchblock::Component::Record::Resume.new }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                ami_client.should_receive(:send_action).and_return RubyAMI::Response.new
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "resumes the recording via AMI" do
                ami_client.should_receive(:send_action).once.with('ResumeMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
