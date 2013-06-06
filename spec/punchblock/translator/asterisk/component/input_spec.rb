# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Input do
          include HasMockCallbackConnection

          let(:media_engine)    { nil }
          let(:ami_client)      { mock('AMI') }
          let(:translator)      { Punchblock::Translator::Asterisk.new ami_client, connection, media_engine }
          let(:call)            { Punchblock::Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }
          let(:original_command_options) { {} }

          let :original_command do
            Punchblock::Component::Input.new original_command_options
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

          subject { Input.new original_command, call }

          describe '#execute' do
            before { original_command.request! }

            it "calls send_progress on the call" do
              call.should_receive(:send_progress)
              subject.execute
            end

            before { call.stub :send_progress }

            let(:original_command_opts) { {} }

            let :original_command_options do
              { :mode => :dtmf, :grammar => { :value => grammar } }.merge(original_command_opts)
            end

            def ami_event_for_dtmf(digit, position)
              RubyAMI::Event.new 'DTMF',
                'Digit' => digit.to_s,
                'Start' => position == :start ? 'Yes' : 'No',
                'End'   => position == :end ? 'Yes' : 'No'
            end

            def send_ami_events_for_dtmf(digit)
              call.process_ami_event ami_event_for_dtmf(digit, :start)
              call.process_ami_event ami_event_for_dtmf(digit, :end)
            end

            let(:reason) { original_command.complete_event(5).reason }

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

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "dtmf-1 dtmf-2"
                      input "12", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Punchblock::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                it "should send a success complete event with the relevant data" do
                  reason.should be == expected_event
                end

                it "should not process further dtmf events" do
                  subject.async.should_receive(:process_dtmf).never
                  send_ami_events_for_dtmf 3
                end
              end

              context "when the match is invalid" do
                before do
                  send_ami_events_for_dtmf 1
                  send_ami_events_for_dtmf '#'
                end

                let :expected_event do
                  Punchblock::Component::Input::Complete::NoMatch.new
                end

                it "should send a nomatch complete event" do
                  reason.should be == expected_event
                end
              end
            end

            describe 'grammar' do
              context 'unset' do
                let(:original_command_opts) { { :grammar => nil } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A grammar document is required.'
                  original_command.response(0.1).should be == error
                end
              end

              context 'with multiple grammars' do
                let(:original_command_opts) { { :grammars => [{:value => grammar}, {:value => grammar}] } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'Only a single grammar is supported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'mode' do
              context 'unset' do
                let(:original_command_opts) { { :mode => nil } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context 'any' do
                let(:original_command_opts) { { :mode => :any } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context 'speech' do
                let(:original_command_opts) { { :mode => :speech } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'terminator' do
              context 'set' do
                let(:original_command_opts) { { terminator: '#' } }

                before do
                  subject.execute
                  expected_event
                end

                let :grammar do
                  RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                    rule id: 'digits' do
                      item repeat: '2-5' do
                        one_of do
                          0.upto(9) { |d| item { d.to_s } }
                        end
                      end
                    end
                  end
                end

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "dtmf-1 dtmf-2"
                      input "12", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Punchblock::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                context "when encountered with a match" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf 2
                    send_ami_events_for_dtmf '#'
                  end

                  it "should send a match complete event with the relevant data" do
                    reason.should be == expected_event
                  end

                  it "should not process further dtmf events" do
                    subject.async.should_receive(:process_dtmf).never
                    send_ami_events_for_dtmf 3
                  end
                end

                context "when encountered with a NoMatch" do
                  before do
                    send_ami_events_for_dtmf '#'
                  end

                  let :expected_event do
                    Punchblock::Component::Input::Complete::NoMatch.new
                  end

                  it "should send a nomatch complete event with the relevant data" do
                    reason.should be == expected_event
                  end
                end

                context "when encountered with a PotentialMatch" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf '#'
                  end

                  let :expected_event do
                    Punchblock::Component::Input::Complete::NoMatch.new
                  end

                  it "should send a nomatch complete event with the relevant data" do
                    reason.should be == expected_event
                  end
                end
              end
            end

            describe 'recognizer' do
              pending
            end

            describe 'initial-timeout' do
              context 'a positive number' do
                let(:original_command_opts) { { :initial_timeout => 1000 } }

                it "should not cause a NoInput if first input is received in time" do
                  subject.execute
                  send_ami_events_for_dtmf 1
                  sleep 1.5
                  send_ami_events_for_dtmf 2
                  reason.should be_a Punchblock::Component::Input::Complete::Match
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
                let(:original_command_opts) { { :initial_timeout => -1 } }

                it "should not start a timer" do
                  subject.wrapped_object.should_receive(:begin_initial_timer).never
                  subject.execute
                end
              end

              context 'unset' do
                let(:original_command_opts) { { :initial_timeout => nil } }

                it "should not start a timer" do
                  subject.wrapped_object.should_receive(:begin_initial_timer).never
                  subject.execute
                end
              end

              context 'a negative number other than -1' do
                let(:original_command_opts) { { :initial_timeout => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An initial timeout value that is negative (and not -1) is invalid.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'inter-digit-timeout' do
              context 'a positive number' do
                let(:original_command_opts) { { :inter_digit_timeout => 1000 } }

                it "should not prevent a Match if input is received in time" do
                  subject.execute
                  sleep 1.5
                  send_ami_events_for_dtmf 1
                  sleep 0.5
                  send_ami_events_for_dtmf 2
                  reason.should be_a Punchblock::Component::Input::Complete::Match
                end

                it "should cause a NoMatch complete event to be sent after the timeout" do
                  subject.execute
                  sleep 1.5
                  send_ami_events_for_dtmf 1
                  sleep 1.5
                  send_ami_events_for_dtmf 2
                  reason.should be_a Punchblock::Component::Input::Complete::NoMatch
                end

                context "with a trailing range repeat" do
                  let :grammar do
                    RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                      rule id: 'digits', scope: 'public' do
                        item repeat: '2-5' do
                          '1'
                        end
                      end
                    end
                  end

                  context "when the buffer potentially matches the grammar" do
                    it "should cause a NoMatch complete event to be sent after the timeout" do
                      subject.execute
                      sleep 1.5
                      send_ami_events_for_dtmf 1
                      sleep 1.5
                      reason.should be_a Punchblock::Component::Input::Complete::NoMatch
                    end
                  end

                  context "when the buffer matches the grammar" do
                    let :expected_nlsml do
                      RubySpeech::NLSML.draw do
                        interpretation confidence: 1 do
                          instance "dtmf-1 dtmf-1"
                          input '11', mode: :dtmf
                        end
                      end.root
                    end

                    it "should fire a match on timeout" do
                      subject.execute
                      sleep 1.5
                      send_ami_events_for_dtmf 1
                      sleep 0.5
                      send_ami_events_for_dtmf 1
                      sleep 1.5
                      reason.should be_a Punchblock::Component::Input::Complete::Match
                      reason.nlsml.should == expected_nlsml
                    end

                    context "on the first keypress" do
                      let :grammar do
                        RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                          rule id: 'digits', scope: 'public' do
                            item repeat: '1-5' do
                              '1'
                            end
                          end
                        end
                      end

                      it "should fire a match on timeout" do
                        subject.execute
                        sleep 1.5
                        send_ami_events_for_dtmf 1
                        sleep 0.5
                        send_ami_events_for_dtmf 1
                        sleep 1.5
                        reason.should be_a Punchblock::Component::Input::Complete::Match
                        reason.nlsml.should == expected_nlsml
                      end
                    end
                  end
                end
              end

              context '-1' do
                let(:original_command_opts) { { :inter_digit_timeout => -1 } }

                it "should not start a timer" do
                  subject.wrapped_object.should_receive(:begin_inter_digit_timer).never
                  subject.execute
                end
              end

              context 'unset' do
                let(:original_command_opts) { { :inter_digit_timeout => nil } }

                it "should not start a timer" do
                  subject.wrapped_object.should_receive(:begin_inter_digit_timer).never
                  subject.execute
                end
              end

              context 'a negative number other than -1' do
                let(:original_command_opts) { { :inter_digit_timeout => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An inter-digit timeout value that is negative (and not -1) is invalid.'
                  original_command.response(0.1).should be == error
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
                command.request!
                original_command.request!
                original_command.execute!
              end

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
