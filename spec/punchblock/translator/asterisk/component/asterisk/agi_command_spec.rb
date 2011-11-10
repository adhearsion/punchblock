require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AGICommand do
            let(:channel)       { 'SIP/foo' }
            let(:mock_call)     { mock 'Call', :channel => channel }
            let(:component_id)  { UUIDTools::UUID.random_create }

            before { UUIDTools::UUID.stubs :random_create => component_id }

            let :command do
              Punchblock::Component::Asterisk::AGI::Command.new :name => 'EXEC ANSWER'
            end

            subject { AGICommand.new command, mock_call }

            let :expected_action do
              RubyAMI::Action.new 'AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => component_id
            end

            context 'initial execution' do
              it 'should send the appropriate RubyAMI::Action' do
                mock_call.expects(:send_ami_action!).once.with(expected_action).returns(expected_action)
                subject.execute
              end
            end

            context 'when the AMI action completes' do
              before do
                command.request!
                command.execute!
              end

              let :expected_response do
                Ref.new :id => component_id
              end

              let :response do
                RubyAMI::Response.new.tap do |r|
                  r['ActionID'] = "552a9d9f-46d7-45d8-a257-06fe95f48d99"
                  r['Message']  = 'Added AGI command to queue'
                end
              end

              it 'should send the component node a ref with the action ID' do
                command.expects(:response=).once.with(expected_response)
                subject.action << response
              end

              context 'with an error' do
                let :error do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                it 'should send the component node false' do
                  command.expects(:response=).once.with false
                  subject.action << error
                end
              end
            end

            describe 'when receiving an AsyncAGI event' do
              before do
                command.request!
                command.execute!
              end

              context 'of type start'

              context 'of type End' do
                let(:ami_event) do
                  RubyAMI::Event.new("AGIExec").tap do |e|
                    e["SubEvent"]   = "End"
                    e["Channel"]    = channel
                    e["CommandId"]  = component_id
                    e["Command"]    = "EXEC ANSWER"
                    e["ResultCode"] = "200"
                    e["Result"]     = "Success"
                    e["Data"]       = "FOO"
                  end
                end

                let :expected_complete_reason do
                  Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code    => 200,
                                                                                       :result  => 'Success',
                                                                                       :data    => 'FOO'
                end

                it 'should send a complete event' do
                  subject.handle_ami_event ami_event

                  command.should be_complete

                  complete_event = command.complete_event.resource(0.5)

                  complete_event.component_id.should == subject.id
                  complete_event.reason.should == expected_complete_reason
                end
              end
            end
          end
        end
      end
    end
  end
end
