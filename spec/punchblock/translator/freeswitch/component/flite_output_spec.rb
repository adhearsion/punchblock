# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      module Component
        describe FliteOutput do
          let(:connection) do
            mock_connection_with_event_handler do |event|
              original_command.add_event event
            end
          end
          let(:media_engine)  { :flite }
          let(:translator)    { Punchblock::Translator::Freeswitch.new connection }
          let(:mock_call)     { Punchblock::Translator::Freeswitch::Call.new 'foo', translator }

          let :original_command do
            Punchblock::Component::Output.new command_options
          end

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let :command_options do
            { :ssml => ssml_doc }
          end

          def execute
            subject.execute media_engine
          end

          subject { described_class.new original_command, mock_call }

          describe '#execute' do
            before { original_command.request! }
            def expect_playback(voice = 'kal')
              subject.wrapped_object.expects(:application).once.with :speak, "#{media_engine}|#{voice}|FOO"
            end

            let(:command_opts) { {} }

            let :command_options do
              { :ssml => ssml_doc }.merge(command_opts)
            end

            let :original_command do
              Punchblock::Component::Output.new command_options
            end

            describe 'ssml' do
              context 'unset' do
                let(:command_opts) { { :ssml => nil } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                  original_command.response(0.1).should be == error
                end
              end

              context 'with an SSML node' do
                it 'should speak the document using the speak application' do
                  expect_playback
                  execute
                end

                it 'should send a complete event when the speak finishes' do
                  expect_playback.yields true
                  execute
                  subject.handle_es_event RubyFS::Event.new(nil, :event_name => "CHANNEL_EXECUTE_COMPLETE")
                  original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
                end
              end
            end

            describe 'start-offset' do
              context 'unset' do
                let(:command_opts) { { :start_offset => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  execute
                end
              end

              context 'set' do
                let(:command_opts) { { :start_offset => 10 } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'start-paused' do
              context 'false' do
                let(:command_opts) { { :start_paused => false } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  execute
                end
              end

              context 'true' do
                let(:command_opts) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'repeat-interval' do
              context 'unset' do
                let(:command_opts) { { :repeat_interval => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  execute
                end
              end

              context 'set' do
                let(:command_opts) { { :repeat_interval => 10 } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'repeat-times' do
              context 'unset' do
                let(:command_opts) { { :repeat_times => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  execute
                end
              end

              context 'set' do
                let(:command_opts) { { :repeat_times => 2 } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'max-time' do
              context 'unset' do
                let(:command_opts) { { :max_time => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  execute
                end
              end

              context 'set' do
                let(:command_opts) { { :max_time => 30 } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'voice' do
              context 'unset' do
                let(:command_opts) { { :voice => nil } }
                it 'should use the default voice' do
                  expect_playback
                  execute
                end
              end

              context 'set' do
                let(:command_opts) { { :voice => 'alison' } }
                it "should execute speak with the specified voice" do
                  expect_playback 'alison'
                  execute
                end
              end
            end

            describe 'interrupt_on' do
              context "set to nil" do
                let(:command_opts) { { :interrupt_on => nil } }
                it "should not pass any digits to Playback" do
                  expect_playback
                  execute
                end
              end

              context "set to :any" do
                let(:command_opts) { { :interrupt_on => :any } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of any is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context "set to :dtmf" do
                let(:command_opts) { { :interrupt_on => :dtmf } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of dtmf is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context "set to :speech" do
                let(:command_opts) { { :interrupt_on => :speech } }
                it "should return an error and not execute any actions" do
                  execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
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
              let :ami_event do
                RubyAMI::Event.new('AsyncAGI').tap do |e|
                  e['SubEvent'] = "Start"
                  e['Channel']  = channel
                  e['Env']      = "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
                end
              end

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                pending
                mock_call.expects(:redirect_back!)
                execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                pending
                mock_call.expects(:redirect_back!)
                execute_command command
                original_command.should_not be_complete
                mock_call.process_ami_event! ami_event
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end

              it "redirects the call by unjoining it" do
                pending
                mock_call.expects(:redirect_back!).with(nil)
                execute_command command
              end
            end
          end
        end

      end
    end
  end
end
