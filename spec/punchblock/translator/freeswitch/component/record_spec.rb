# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      module Component
        describe Record do
          include HasMockCallbackConnection

          let(:id)          { Punchblock.new_uuid }
          let(:translator)  { Punchblock::Translator::Freeswitch.new connection }
          let(:mock_stream) { mock('RubyFS::Stream') }
          let(:mock_call)   { Punchblock::Translator::Freeswitch::Call.new id, translator, nil, mock_stream }

          let :original_command do
            Punchblock::Component::Record.new command_options
          end

          let :command_options do
            {}
          end

          before do
            mock_stream.as_null_object
            mock_call.stub(:uuid_foo)
          end

          subject { Record.new original_command, mock_call }

          let(:filename)  { "#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav" }

          describe '#execute' do
            let(:reason)    { original_command.complete_event(5).reason }
            let(:recording) { original_command.complete_event(5).recording }

            before { original_command.request! }

            it "sets command response to a reference to the component" do
              subject.execute
              original_command.response(0.1).should be_a Ref
              original_command.component_id.should be == subject.id
            end

            it "starts a recording via uuid_record, using the component ID as the filename" do
              mock_call.should_receive(:uuid_foo).once.with(:record, "start #{filename}")
              subject.execute
            end

            it "sends a success complete event when the recording ends" do
              full_filename = "file://#{filename}"
              subject.execute
              record_stop_event = RubyFS::Event.new nil, {
                :event_name       => 'RECORD_STOP',
                :record_file_path => filename
              }
              mock_call.handle_es_event record_stop_event
              reason.should be_a Punchblock::Component::Record::Complete::Success
              recording.uri.should be == full_filename
              original_command.should be_complete
            end

            describe 'start_paused' do
              context "set to nil" do
                let(:command_options) { { :start_paused => nil } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_paused => false } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  mock_call.should_receive(:uuid_foo).never
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A start-paused value of true is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'initial_timeout' do
              context "set to nil" do
                let(:command_options) { { :initial_timeout => nil } }
                it "should setvar RECORD_INITIAL_TIMEOUT_MS with a 0 value" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_INITIAL_TIMEOUT_MS 0").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :initial_timeout => -1 } }
                it "should setvar RECORD_INITIAL_TIMEOUT_MS with a 0 value" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_INITIAL_TIMEOUT_MS 0").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :initial_timeout => 10 } }
                it "should setvar RECORD_INITIAL_TIMEOUT_MS with a value in ms" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_INITIAL_TIMEOUT_MS 10").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
            end

            describe 'final_timeout' do
              context "set to nil" do
                let(:command_options) { { :final_timeout => nil } }
                it "should setvar RECORD_FINAL_TIMEOUT_MS with a 0 value" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_FINAL_TIMEOUT_MS 0").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :final_timeout => -1 } }
                it "should setvar RECORD_FINAL_TIMEOUT_MS with a 0 value" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_FINAL_TIMEOUT_MS 0").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :final_timeout => 10 } }
                it "should setvar RECORD_FINAL_TIMEOUT_MS with a value in ms" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_FINAL_TIMEOUT_MS 10").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
            end

            describe 'format' do
              context "set to nil" do
                let(:command_options) { { :format => nil } }
                it "should execute as 'wav'" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  mock_call.should_receive(:uuid_foo)
                  subject.execute
                  record_stop_event = RubyFS::Event.new nil, {
                    :event_name       => 'RECORD_STOP',
                    :record_file_path => "#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                  }
                  mock_call.handle_es_event record_stop_event
                  recording.uri.should match(/.*\.wav$/)
                end
              end

              context "set to 'mp3'" do
                let(:command_options) { { :format => 'mp3' } }
                it "should execute as 'mp3'" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.mp3/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                it "provides the correct filename in the recording" do
                  mock_call.should_receive(:uuid_foo)
                  subject.execute
                  record_stop_event = RubyFS::Event.new nil, {
                    :event_name       => 'RECORD_STOP',
                    :record_file_path => "#{Record::RECORDING_BASE_PATH}/#{subject.id}.mp3"
                  }
                  mock_call.handle_es_event record_stop_event
                  recording.uri.should match(/.*\.mp3$/)
                end
              end
            end

            describe 'start_beep' do
              context "set to nil" do
                let(:command_options) { { :start_beep => nil } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_beep => false } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_beep => true } }

                it "should return an error and not execute any actions" do
                  mock_call.should_receive(:uuid_foo).never
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A start-beep value of true is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'max_duration' do
              context "set to nil" do
                let(:command_options) { { :max_duration => nil } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :max_duration => -1 } }
                it "should execute normally" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/)
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

                it "executes the recording with a time limit" do
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav 1$/)
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
            end

            describe 'direction' do
              context "with nil" do
                let(:command_options) { { :direction => nil } }
                it "should execute the setvar application with duplex options before recording" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_STEREO true").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
              context "with :duplex" do
                let(:command_options) { { :direction => :duplex } }
                it "should execute the setvar application with duplex options before recording" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_STEREO true").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
              context "with :send" do
                let(:command_options) { { :direction => :send } }
                it "should execute the setvar application with send options before recording" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_WRITE_ONLY true").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end
              end
              context "with :recv" do
                let(:command_options) { { :direction => :recv } }
                it "should execute the setvar application with recv options before recording" do
                  mock_call.should_receive(:uuid_foo).once.with(:setvar, "RECORD_READ_ONLY true").ordered
                  mock_call.should_receive(:uuid_foo).once.with(:record, /.wav$/).ordered
                  subject.execute
                  original_command.response(0.1).should be_a Ref
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
                command.request!
                original_command.request!
                subject.execute
              end

              let :send_stop_event do
                record_stop_event = RubyFS::Event.new nil, {
                  :event_name       => 'RECORD_STOP',
                  :record_file_path => filename
                }
                mock_call.handle_es_event record_stop_event
              end

              it "sets the command response to true" do
                mock_call.should_receive :uuid_foo
                subject.execute_command command
                send_stop_event
                command.response(0.1).should be == true
              end

              it "executes a uuid_record stop command" do
                mock_call.should_receive(:uuid_foo).with(:record, "stop #{filename}")
                subject.execute_command command
              end

              it "sends the correct complete event" do
                mock_call.should_receive(:uuid_foo).with(:record, "stop #{filename}")
                subject.execute_command command
                send_stop_event
                reason.should be_a Punchblock::Event::Complete::Stop
                recording.uri.should be == "file://#{filename}"
                original_command.should be_complete
              end
            end

            context "with a Pause command" do
              let(:command) { Punchblock::Component::Record::Pause.new }

              before do
                pending
                mock_call.should_receive :uuid_foo
                command.request!
                original_command.request!
                subject.execute
              end

              it "sets the command response to true" do
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "pauses the recording via AMI" do
                mock_call.should_receive(:uuid_foo).once.with('PauseMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end

            context "with a Resume command" do
              let(:command) { Punchblock::Component::Record::Resume.new }

              before do
                pending
                mock_call.should_receive :uuid_foo
                command.request!
                original_command.request!
                subject.execute
              end

              it "sets the command response to true" do
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "resumes the recording via AMI" do
                mock_call.should_receive(:uuid_foo).once.with('ResumeMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
