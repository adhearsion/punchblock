# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Input do
          let(:connection) do
            mock_connection_with_event_handler do |event|
              command.add_event event
            end
          end
          let(:media_engine)    { nil }
          let(:translator)      { Punchblock::Translator::Asterisk.new mock('AMI'), connection, media_engine }
          let(:call)            { Punchblock::Translator::Asterisk::Call.new 'foo', translator }
          let(:command_options) { {} }

          let :command do
            Punchblock::Component::Input.new command_options
          end

          let :grammar do
            RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'pin' do
              rule id: 'digit' do
                one_of do
                  0.upto(9) { |d| item { d.to_s } }
                end
              end

              rule id: 'pin', scope: 'public' do
                item repeat: '2' do
                  ruleref uri: '#digit'
                end
              end
            end
          end

          subject { Input.new command, call }

          describe '#execute' do
            before { command.request! }

            it "calls answer_if_not_answered on the call" do
              call.expects :answer_if_not_answered
              subject.execute
            end

            before { call.stubs :answer_if_not_answered }

            context 'with a media engine of :unimrcp' do
              pending
              let(:media_engine) { :unimrcp }
            end

            context 'with a media engine of :asterisk' do
              let(:media_engine) { :asterisk }

              let(:command_opts) { {} }

              let :command_options do
                { :mode => :dtmf, :grammar => { :value => grammar } }.merge(command_opts)
              end

              def ami_event_for_dtmf(digit, position)
                RubyAMI::Event.new('DTMF').tap do |e|
                  e['Digit']  = digit.to_s
                  e['Start']  = position == :start ? 'Yes' : 'No'
                  e['End']    = position == :end ? 'Yes' : 'No'
                end
              end

              def send_ami_events_for_dtmf(digit)
                call.process_ami_event ami_event_for_dtmf(digit, :start)
                call.process_ami_event ami_event_for_dtmf(digit, :end)
              end

              let(:reason) { command.complete_event(5).reason }

              describe "receiving DTMF events" do
                before do
                  subject.execute
                  expected_event
                end

                context "when a match is found" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf 2
                  end

                  let :expected_event do
                    Punchblock::Component::Input::Complete::Success.new :mode => :dtmf,
                      :confidence => 1,
                      :utterance => '12',
                      :interpretation => 'dtmf-1 dtmf-2',
                      :component_id => subject.id,
                      :call_id => call.id
                  end

                  it "should send a success complete event with the relevant data" do
                    reason.should be == expected_event
                  end
                end

                context "when the match is invalid" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf '#'
                  end

                  let :expected_event do
                    Punchblock::Component::Input::Complete::NoMatch.new :component_id => subject.id,
                                                                        :call_id => call.id
                  end

                  it "should send a nomatch complete event" do
                    reason.should be == expected_event
                  end
                end
              end

              describe 'grammar' do
                context 'unset' do
                  let(:command_opts) { { :grammar => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'A grammar document is required.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'mode' do
                context 'unset' do
                  let(:command_opts) { { :mode => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end

                context 'any' do
                  let(:command_opts) { { :mode => :any } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end

                context 'speech' do
                  let(:command_opts) { { :mode => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'terminator' do
                pending
              end

              describe 'recognizer' do
                pending
              end

              describe 'initial-timeout' do
                context 'a positive number' do
                  let(:command_opts) { { :initial_timeout => 1000 } }

                  it "should not cause a NoInput if first input is received in time" do
                    subject.execute
                    send_ami_events_for_dtmf 1
                    sleep 1.5
                    send_ami_events_for_dtmf 2
                    reason.should be_a Punchblock::Component::Input::Complete::Success
                  end

                  it "should cause a NoInput complete event to be sent after the timeout" do
                    subject.execute
                    sleep 1.5
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf 2
                    reason.should be_a Punchblock::Component::Input::Complete::NoInput
                  end
                end

                context '-1' do
                  let(:command_opts) { { :initial_timeout => -1 } }

                  it "should not start a timer" do
                    subject.wrapped_object.expects(:begin_initial_timer).never
                    subject.execute
                  end
                end

                context 'unset' do
                  let(:command_opts) { { :initial_timeout => nil } }

                  it "should not start a timer" do
                    subject.wrapped_object.expects(:begin_initial_timer).never
                    subject.execute
                  end
                end

                context 'a negative number other than -1' do
                  let(:command_opts) { { :initial_timeout => -1000 } }

                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'An initial timeout value that is negative (and not -1) is invalid.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'inter-digit-timeout' do
                context 'a positive number' do
                  let(:command_opts) { { :inter_digit_timeout => 1000 } }

                  it "should not prevent a Match if input is received in time" do
                    subject.execute
                    sleep 1.5
                    send_ami_events_for_dtmf 1
                    sleep 0.5
                    send_ami_events_for_dtmf 2
                    reason.should be_a Punchblock::Component::Input::Complete::Success
                  end

                  it "should cause a NoMatch complete event to be sent after the timeout" do
                    subject.execute
                    sleep 1.5
                    send_ami_events_for_dtmf 1
                    sleep 1.5
                    send_ami_events_for_dtmf 2
                    reason.should be_a Punchblock::Component::Input::Complete::NoMatch
                  end
                end

                context '-1' do
                  let(:command_opts) { { :inter_digit_timeout => -1 } }

                  it "should not start a timer" do
                    subject.wrapped_object.expects(:begin_inter_digit_timer).never
                    subject.execute
                  end
                end

                context 'unset' do
                  let(:command_opts) { { :inter_digit_timeout => nil } }

                  it "should not start a timer" do
                    subject.wrapped_object.expects(:begin_inter_digit_timer).never
                    subject.execute
                  end
                end

                context 'a negative number other than -1' do
                  let(:command_opts) { { :inter_digit_timeout => -1000 } }

                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new 'option error', 'An inter-digit timeout value that is negative (and not -1) is invalid.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'sensitivity' do
                pending
              end

              describe 'min-confidence' do
                pending
              end

              describe 'max-silence' do
                pending
              end
            end
          end

          describe "#execute_command" do
            context "with a command it does not understand" do
              let(:command) { Punchblock::Component::Output::Pause.new command_options}
              before{ command.request! }
              it "returns a ProtocolError response" do 
                subject.execute_command command
                command.response(0.1).should be_a ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Punchblock::Component::Stop.new command_options}
              let(:reason) { command.complete_event(5).reason }
              before{ command.request! }
              it "sets the command response to true" do 
                subject.execute_command command
                command.response(0.1).should be == true
                reason.should be_a Punchblock::Event::Complete::Stop
              end
            end
          end

        end
      end
    end
  end
end
