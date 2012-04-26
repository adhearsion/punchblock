# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Record do
          let(:connection) do
            mock_connection_with_event_handler do |event|
              original_command.add_event event
            end
          end
          let(:media_engine)  { nil }
          let(:channel)       { 'SIP/foo' }
          let(:translator)    { Punchblock::Translator::Asterisk.new mock('AMI'), connection, media_engine }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new channel, translator }

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

            it "calls answer_if_not_answered on the call" do
              mock_call.expects :answer_if_not_answered
              subject.execute
            end

            before { mock_call.stubs :answer_if_not_answered }

            it "sets command response to a reference to the component" do
              mock_call.expects(:send_ami_action!)
              subject.execute
              original_command.response(0.1).should be_a Ref
              original_command.component_id.should be == subject.id
            end

            it "starts a recording via AMI, using the component ID as the filename" do
              filename = "#{Record::RECORDING_BASE_PATH}/#{subject.id}"
              mock_call.expects(:send_ami_action!).once.with('Monitor', 'Channel' => channel, 'File' => filename, 'Format' => 'wav', 'Mix' => true)
              subject.execute
            end

            it "sends a success complete event when the recording ends" do
              full_filename = "#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
              mock_call.expects(:send_ami_action!)
              subject.execute
              monitor_stop_event = RubyAMI::Event.new('MonitorStop').tap do |e|
                e['Channel'] = channel
              end
              mock_call.process_ami_event monitor_stop_event
              reason.should be_a Punchblock::Component::Record::Complete::Success
              recording.uri.should be == full_filename
              original_command.should be_complete
            end
          end

          describe "#execute_command" do
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
              let(:reason) { original_command.complete_event(5).reason }

              before do
                mock_call.expects :answer_if_not_answered
                mock_call.expects :send_ami_action!
                command.request!
                original_command.request!
                subject.execute
              end

              let :send_stop_event do
                monitor_stop_event = RubyAMI::Event.new('MonitorStop').tap do |e|
                  e['Channel'] = channel
                end
                mock_call.process_ami_event monitor_stop_event
              end

              it "sets the command response to true" do
                mock_call.expects(:send_ami_action!)
                subject.execute_command command
                send_stop_event
                command.response(0.1).should be == true
              end

              it "executes a StopMonitor action" do
                mock_call.expects(:send_ami_action!).once.with('StopMonitor', 'Channel' => channel)
                subject.execute_command command
              end

              it "sends the correct complete event" do
                def mock_call.send_ami_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new if block
                end
                subject.execute_command command
                send_stop_event
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end
            end

            context "with a Pause command" do
              let(:command) { Punchblock::Component::Record::Pause.new }
              let(:reason) { original_command.complete_event(5).reason }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                def mock_call.send_ami_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new if block
                end
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "pauses the recording via AMI" do
                mock_call.expects(:send_ami_action!).once.with('PauseMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end

            context "with a Resume command" do
              let(:command) { Punchblock::Component::Record::Resume.new }
              let(:reason) { original_command.complete_event(5).reason }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                def mock_call.send_ami_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new if block
                end
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "resumes the recording via AMI" do
                mock_call.expects(:send_ami_action!).once.with('ResumeMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
