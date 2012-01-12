require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AGICommand do
            let(:channel)       { 'SIP/foo' }
            let(:connection) do
              mock_connection_with_event_handler do |event|
                command.add_event event
              end
            end
            let(:translator)    { Punchblock::Translator::Asterisk.new mock('AMI'), connection }
            let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new channel, translator }
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

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                let :expected_action do
                  RubyAMI::Action.new 'AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => component_id
                end

                let :command do
                  Punchblock::Component::Asterisk::AGI::Command.new :name => 'WAIT FOR DIGIT', :params => params
                end

                it 'should send the appropriate RubyAMI::Action' do
                  mock_call.expects(:send_ami_action!).once.with(expected_action).returns(expected_action)
                  subject.execute
                end
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

                  command.should be_complete

                  complete_event = command.complete_event 0.5

                  complete_event.component_id.should == component_id.to_s
                  complete_event.reason.should == expected_complete_reason
                end
              end
            end

            describe '#parse_agi_result' do
              context 'with a simple result with no data' do
                let(:result_string) { "200%20result=123%0A" }

                it 'should provide the code and result' do
                  code, result, data = subject.parse_agi_result result_string
                  code.should   == 200
                  result.should == 123
                  data.should   == ''
                end
              end

              context 'with a result and data in parens' do
                let(:result_string) { "200%20result=-123%20(timeout)%0A" }

                it 'should provide the code and result' do
                  code, result, data = subject.parse_agi_result result_string
                  code.should   == 200
                  result.should == -123
                  data.should   == 'timeout'
                end
              end

              context 'with a result and key-value data' do
                let(:result_string) { "200%20result=123%20foo=bar%0A" }

                it 'should provide the code and result' do
                  code, result, data = subject.parse_agi_result result_string
                  code.should   == 200
                  result.should == 123
                  data.should   == 'foo=bar'
                end
              end
            end
          end
        end
      end
    end
  end
end
