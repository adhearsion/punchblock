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
            let(:ami_client)    { stub('AMI Client').as_null_object }
            let(:translator)    { Punchblock::Translator::Asterisk.new ami_client, connection }
            let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new channel, translator, ami_client, connection }
            let(:component_id)  { Punchblock.new_uuid }

            before { stub_uuids component_id }

            let :original_command do
              Punchblock::Component::Asterisk::AGI::Command.new :name => 'EXEC ANSWER'
            end

            subject { AGICommand.new original_command, mock_call }

            let :response do
              RubyAMI::Response.new
            end

            context 'initial execution' do
              before { original_command.request! }

              it 'should send the appropriate action' do
                ami_client.should_receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => component_id).and_return(response)
                subject.execute
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                let :original_command do
                  Punchblock::Component::Asterisk::AGI::Command.new :name => 'WAIT FOR DIGIT', :params => params
                end

                it 'should send the appropriate action' do
                  ami_client.should_receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => component_id).and_return(response)
                  subject.execute
                end
              end
            end

            context 'when the AMI action completes' do
              before do
                original_command.request!
              end

              let :expected_response do
                Ref.new uri: component_id
              end

              let :response do
                RubyAMI::Response.new 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
                  'Message' => 'Added AGI original_command to queue'
              end

              it 'should send the component node a ref with the action ID' do
                ami_client.should_receive(:send_action).once.and_return response
                subject.execute
                original_command.response(1).should == expected_response
              end

              context 'with an error' do
                let :response do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                it 'should send the component node false' do
                  ami_client.should_receive(:send_action).once.and_raise response
                  subject.execute
                  original_command.response(1).should be_false
                  subject.should_not be_alive
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
                  RubyAMI::Event.new 'AsyncAGI',
                    "SubEvent"   => "Exec",
                    "Channel"    => channel,
                    "CommandId"  => component_id,
                    "Command"    => "EXEC ANSWER",
                    "Result"     => "200%20result=123%20(timeout)%0A"
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

                  let(:chan_var) { nil }

                  before do
                    response = RubyAMI::Response.new 'Value' => chan_var
                    ami_client.should_receive(:send_action).once.with('GetVar', 'Channel' => channel, 'Variable' => 'PUNCHBLOCK_END_ON_ASYNCAGI_BREAK').and_return response
                  end

                  it 'should not send an end (hangup) event to the translator' do
                    translator.should_receive(:handle_pb_event).once.with kind_of(Punchblock::Event::Complete)
                    translator.should_receive(:handle_pb_event).never.with kind_of(Punchblock::Event::End)
                    subject.handle_ami_event ami_event
                  end

                  context "when the PUNCHBLOCK_END_ON_ASYNCAGI_BREAK channel var is set" do
                    let(:chan_var) { 'true' }

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
end
