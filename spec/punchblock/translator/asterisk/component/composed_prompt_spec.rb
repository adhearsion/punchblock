# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe ComposedPrompt do
          class MockConnection
            attr_reader :events

            def initialize
              @events = []
            end

            def handle_event(event)
              @events << event
            end
          end

          let(:connection)    { MockConnection.new }
          let(:media_engine)  { nil }
          let(:ami_client)    { mock('AMI') }
          let(:translator)    { Punchblock::Translator::Asterisk.new ami_client, connection, media_engine }
          let(:call)          { Punchblock::Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }

          let :ssml_doc do
            RubySpeech::SSML.draw do
              audio src: 'http://foo.com/bar.mp3'
            end
          end

          let :dtmf_grammar do
            RubySpeech::GRXML.draw mode: 'dtmf', root: 'digit' do
              rule id: 'digit' do
                one_of do
                  item { '1' }
                  item { '2' }
                end
              end
            end
          end

          let :output_command_options do
            { render_document: {value: ssml_doc} }
          end

          let :input_command_options do
            {
              mode: :dtmf,
              grammar: {value: dtmf_grammar}
            }
          end

          let(:command_options) { {} }

          let :output_command do
            Punchblock::Component::Output.new output_command_options
          end

          let :input_command do
            Punchblock::Component::Input.new input_command_options
          end

          let :original_command do
            Punchblock::Component::Prompt.new output_command, input_command, command_options
          end

          subject { described_class.new original_command, call }

          before do
            call.stub answered?: true, execute_agi_command: true
            original_command.request!
            output_command.request!
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

          describe '#execute' do
            context '#barge_in' do
              context 'true' do
                it "should execute an output component on the call and return a ref" do
                  call.should_receive(:execute_agi_command).once.with('EXEC Playback', 'http://foo.com/bar.mp3')
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                context "if output fails to start" do
                  it "should return the error returned by output"
                end

                context "receiving dtmf during output" do
                  it "should stop the output"

                  it "should contribute to the input result"

                  it "should return a match complete event"
                end

                context "when not receiving any DTMF input at all" do
                  it "should not start the initial timer until output completes"
                end
              end

              context 'false' do
                it "should execute an output component on the call" do
                  call.should_receive(:execute_agi_command).once.with('EXEC Playback', 'http://foo.com/bar.mp3')
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                context "if output fails to start" do
                  let(:output_response) { ProtocolError.new.setup 'unrenderable document error', 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.' }

                  let :ssml_doc do
                    RubySpeech::SSML.draw do
                      string "Foo Bar"
                    end
                  end

                  it "should return the error returned by output" do
                    subject.execute
                    original_command.response(0.1).should == output_response
                  end
                end

                context "receiving dtmf during output" do
                  it "should not stop the output"

                  it "should not contribute to the input result"
                end

                context "receiving matching dtmf after output completes" do
                  let :expected_nlsml do
                    RubySpeech::NLSML.draw do
                      interpretation confidence: 1 do
                        instance "dtmf-1"
                        input "1", mode: :dtmf
                      end
                    end
                  end

                  let :expected_event do
                    Punchblock::Event::Complete.new reason: expected_reason,
                      component_id: subject.id,
                      target_call_id: call.id
                  end

                  let :expected_reason do
                    Punchblock::Component::Input::Complete::Match.new nlsml: expected_nlsml
                  end

                  it "should return a match complete event" do
                    expected_event
                    subject.execute
                    original_command.response(0.1).should be_a Ref
                    send_ami_events_for_dtmf 1

                    connection.events.should include(expected_event)
                  end
                end

                context "when not receiving any DTMF input at all" do
                  it "should not start the initial timer until output completes"
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
              let(:channel) { "SIP/1234-00000000" }
              let :ami_event do
                RubyAMI::Event.new 'AsyncAGI',
                  'SubEvent'  => "Start",
                  'Channel'   => channel,
                  'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before do
                command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                call.async.should_receive(:redirect_back).once
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                expected_reason = Punchblock::Event::Complete::Stop.new
                expected_event = Punchblock::Event::Complete.new reason: expected_reason,
                  component_id: subject.id,
                  target_call_id: call.id

                call.async.should_receive(:redirect_back)
                subject.execute_command command
                original_command.should_not be_complete
                call.process_ami_event ami_event

                sleep 0.2

                connection.events.should include(expected_event)
              end
            end
          end

        end
      end
    end
  end
end
