# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AGICommand do
            include HasMockCallbackConnection

            let(:channel)       { 'SIP/foo' }
            let(:translator)    { Punchblock::Translator::Asterisk.new mock('AMI'), connection }
            let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new channel, translator }
            let(:component_id)  { Punchblock.new_uuid }

            before { stub_uuids component_id }

            let :original_command do
              Punchblock::Component::Asterisk::AGI::Command.new :name => 'EXEC ANSWER'
            end

            subject { AGICommand.new original_command, mock_call }

            let :expected_action do
              RubyAMI::Action.new 'AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => component_id
            end

            context 'initial execution' do
              before { original_command.request! }

              it 'should send the appropriate RubyAMI::Action' do
                mock_call.should_receive(:send_ami_action).once.with(expected_action).and_return(expected_action)
                subject.execute
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                let :expected_action do
                  RubyAMI::Action.new 'AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => component_id
                end

                let :original_command do
                  Punchblock::Component::Asterisk::AGI::Command.new :name => 'WAIT FOR DIGIT', :params => params
                end

                it 'should send the appropriate RubyAMI::Action' do
                  mock_call.should_receive(:send_ami_action).once.with(expected_action).and_return(expected_action)
                  subject.execute
                end
              end
            end

            context 'when the AMI action completes' do
              before do
                original_command.request!
              end

              let :expected_response do
                Ref.new :id => component_id
              end

              let :response do
                RubyAMI::Response.new.tap do |r|
                  r['ActionID'] = "552a9d9f-46d7-45d8-a257-06fe95f48d99"
                  r['Message']  = 'Added AGI original_command to queue'
                end
              end

              it 'should send the component node a ref with the action ID' do
                original_command.should_receive(:response=).once.with(expected_response)
                subject.action << response
              end

              context 'with an error' do
                let :error do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                it 'should send the component node false' do
                  original_command.should_receive(:response=).once.with false
                  subject.action << error
                end
              end
            end

            describe 'when receiving an AsyncAGI event' do
              before do
                original_command.request!
                original_command.execute!
              end

              context 'of type start'

              context 'of type Exec' do
                let(:ami_event) do
                  RubyAMI::Event.new("AsyncAGI").tap do |e|
                    e["SubEvent"]   = "Exec"
                    e["Channel"]    = channel
                    e["CommandId"]  = component_id
                    e["Command"]    = "EXEC ANSWER"
                    e["Result"]     = "200%20result=123%20(timeout)%0A"
                  end
                end

                let :expected_complete_reason do
                  Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code    => 200,
                                                                                       :result  => 123,
                                                                                       :data    => 'timeout'
                end

                it 'should send a complete event' do
                  subject.handle_ami_event ami_event

                  complete_event = original_command.complete_event 0.5

                  original_command.should be_complete

                  complete_event.component_id.should be == component_id.to_s
                  complete_event.reason.should be == expected_complete_reason
                end

                context "when the command was ASYNCAGI BREAK" do
                  let :original_command do
                    Punchblock::Component::Asterisk::AGI::Command.new :name => 'ASYNCAGI BREAK'
                  end

                  it 'should send an end (hangup) event to the translator' do
                    expected_end_event = Punchblock::Event::End.new reason: :hangup,
                                                                    target_call_id: mock_call.id

                    translator.should_receive(:handle_pb_event).once.with kind_of(Punchblock::Event::Complete)
                    translator.should_receive(:handle_pb_event).once.with expected_end_event
                    subject.handle_ami_event ami_event
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
