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

            it "calls raise_if_not_answered on the call" do
              mock_call.expects :send_ami_action!
              mock_call.expects :raise_if_not_answered
              subject.execute
            end

            before { mock_call.stubs :raise_if_not_answered }

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
              full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
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

            describe 'start_paused' do
              context "set to nil" do
                let(:command_options) { { :start_paused => nil } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_paused => false } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  mock_call.expects(:send_agi_action!).never
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
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :initial_timeout => -1 } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :initial_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  mock_call.expects(:send_agi_action!).never
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
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :final_timeout => -1 } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :final_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  mock_call.expects(:send_agi_action!).never
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
                  mock_call.expects(:send_ami_action!).once.with('Monitor', has_entry('Format' => 'wav'))
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  mock_call.expects(:send_ami_action!)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new('MonitorStop').tap do |e|
                    e['Channel'] = channel
                  end
                  mock_call.process_ami_event monitor_stop_event
                  recording.uri.should match(/.*\.wav$/)
                end
              end

              context "set to 'mp3'" do
                let(:command_options) { { :format => 'mp3' } }
                it "should execute as 'mp3'" do
                  mock_call.expects(:send_ami_action!).once.with('Monitor', has_entry('Format' => 'mp3'))
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  mock_call.expects(:send_ami_action!)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new('MonitorStop').tap do |e|
                    e['Channel'] = channel
                  end
                  mock_call.process_ami_event monitor_stop_event
                  recording.uri.should match(/.*\.mp3$/)
                end
              end
            end

            describe 'start_beep' do
              context "set to nil" do
                let(:command_options) { { :start_beep => nil } }
                it "should execute normally" do
                  mock_call.expects(:send_agi_action!).never.with('STREAM FILE', 'beep', '""')
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_beep => false } }
                it "should execute normally" do
                  mock_call.expects(:send_agi_action!).never.with('STREAM FILE', 'beep', '""')
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_beep => true } }

                it "should play a beep before recording" do
                  execute_seq = sequence 'beep then record'
                  subject.wrapped_object.expects(:wait).once
                  mock_call.expects(:send_agi_action!).once.with('STREAM FILE', 'beep', '""').in_sequence(execute_seq)
                  mock_call.expects(:send_ami_action!).once.in_sequence(execute_seq)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "should wait for the beep to finish before starting recording" do
                  def mock_call.send_agi_action!(*args)
                    yield
                  end
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
            end

            describe 'max_duration' do
              context "set to nil" do
                let(:command_options) { { :max_duration => nil } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :max_duration => -1 } }
                it "should execute normally" do
                  mock_call.expects(:send_ami_action!).once
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
                  mock_call.expects :send_ami_action!
                  mock_call.expects(:send_ami_action!).once.with('StopMonitor', 'Channel' => channel)
                  subject.execute
                  sleep 1.2
                end

                it "sends the correct complete event" do
                  def mock_call.send_ami_action!(*args, &block)
                    block.call Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new if block
                  end
                  full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                  subject.execute
                  sleep 1.2

                  monitor_stop_event = RubyAMI::Event.new('MonitorStop').tap do |e|
                    e['Channel'] = channel
                  end
                  mock_call.process_ami_event monitor_stop_event

                  reason.should be_a Punchblock::Component::Record::Complete::Success
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
                mock_call.expects :send_ami_action!
                mock_call.expects :raise_if_not_answered
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
                mock_call.expects :send_ami_action!
                subject.execute_command command
                send_stop_event
                command.response(0.1).should be == true
              end

              it "executes a StopMonitor action" do
                mock_call.expects(:send_ami_action!).once.with('StopMonitor', 'Channel' => channel)
                subject.execute_command command
              end

              it "sends the correct complete event" do
                mock_call.instance_exec do
                  class << self
                    undef :send_ami_action! # This is here because mocha has already defined #send_ami_action! above. We need to undef it to prevent a warning on redefinition.
                  end

                  def send_ami_action!(*args, &block)
                    block.call Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new if block
                  end
                end

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
