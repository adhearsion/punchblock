require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe AMIAction do
        let(:mock_ami_client) { mock 'RubyAMI::Client' }

        let :command do
          Punchblock::Component::Asterisk::AMI::Action.new :name => 'Status', :params => { :channel => 'foo' }
        end

        subject { AMIAction.new command, mock_ami_client }

        let :expected_action do
          RubyAMI::Action.new 'Status', 'Channel' => 'foo'
        end

        let :expected_complete_event do
          Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => 'Channel status will follow'
        end

        context 'initial execution' do
          let(:component_id) { UUIDTools::UUID.random_create }

          let :expected_response do
            Ref.new :id => component_id
          end

          before { UUIDTools::UUID.stubs :random_create => component_id }

          it 'should send the appropriate RubyAMI::Action and send the component node a ref with the action ID' do
            mock_ami_client.expects(:send_action).once.with(expected_action).returns(expected_action)
            command.expects(:response=).once.with(expected_response)
            subject.execute
          end
        end

        context 'when the AMI action completes' do
          let(:response) do
            RubyAMI::Response.new.tap do |r|
              r['Message'] = 'Channel status will follow'
            end
          end

          it 'should send a complete event to the component node' do
            subject.action.response = response

            command.complete_event.resource(0.5).should == expected_complete_event
          end
        end
      end
    end
  end
end
