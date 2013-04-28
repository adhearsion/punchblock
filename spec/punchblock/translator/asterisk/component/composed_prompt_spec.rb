# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe ComposedPrompt do
          include HasMockCallbackConnection

          let(:media_engine)  { nil }
          let(:ami_client)    { mock('AMI') }
          let(:translator)    { Punchblock::Translator::Asterisk.new ami_client, connection, media_engine }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }

          let :ssml_doc do
            RubySpeech::SSML.draw do
              audio src: 'http://foo.com/bar.mp3'
            end
          end

          let :dtmf_grammar do
            RubySpeech::GRXML.draw mode: 'dtmf', root: 'pin' do
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

          let :output_command_options do
            { render_document: {value: ssml_doc} }
          end

          let :input_command_options do
            { grammar: {value: dtmf_grammar} }
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

          subject { described_class.new original_command, mock_call }

          def expect_answered(value = true)
            mock_call.should_receive(:answered?).at_least(:once).and_return(value)
          end

          describe '#execute' do
            context '#barge_in' do
              context 'true' do

              end

              context 'false' do

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
              let(:channel) { "SIP/1234-00000000" }
              let :ami_event do
                RubyAMI::Event.new 'AsyncAGI',
                  'SubEvent'  => "Start",
                  'Channel'   => channel,
                  'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                mock_call.async.should_receive(:redirect_back).once
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                mock_call.async.should_receive(:redirect_back)
                subject.execute_command command
                original_command.should_not be_complete
                mock_call.process_ami_event ami_event
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end
            end
          end

        end
      end
    end
  end
end
