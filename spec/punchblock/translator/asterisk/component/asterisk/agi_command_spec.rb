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

            let :response do
              RubyAMI::Response.new
            end

            context 'initial execution' do
              before { original_command.request! }

              it 'should send the appropriate action' do
                mock_call.should_receive(:send_ami_action).once.with('AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => component_id).and_return(response)
                subject.execute
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                let :original_command do
                  Punchblock::Component::Asterisk::AGI::Command.new :name => 'WAIT FOR DIGIT', :params => params
                end

                it 'should send the appropriate action' do
                  mock_call.should_receive(:send_ami_action).once.with('AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => component_id).and_return(response)
                  subject.execute
                end
              end
            end

            context 'when the AMI action completes' do
              before do
                original_command.request!
                mock_call.should_receive(:send_ami_action).once.and_return(response)
              end

              let :expected_response do
                Ref.new :id => component_id
              end

              let :response do
                RubyAMI::Response.new 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
                  'Message' => 'Added AGI original_command to queue'
              end

              it 'should send the component node a ref with the action ID' do
                subject.execute
                original_command.response(1).should eql(expected_response)
              end

              context 'with an error' do
                let :response do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                it 'should send the component node false' do
                  subject.execute
                  original_command.response(1).should be_false
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
              end
            end
          end
        end
      end
    end
  end
end
