# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AMIAction do
            include HasMockCallbackConnection

            let(:mock_translator) { Punchblock::Translator::Asterisk.new mock('AMI'), connection }

            let :original_command do
              Punchblock::Component::Asterisk::AMI::Action.new :name => 'ExtensionStatus', :params => { :context => 'default', :exten => 'idonno' }
            end

            before do
              original_command.request!
            end

            subject { AMIAction.new original_command, mock_translator }

            context 'initial execution' do
              let(:component_id) { Punchblock.new_uuid }

              let :expected_response do
                Ref.new :id => component_id
              end

              before { stub_uuids component_id }

              it 'should send the appropriate RubyAMI::Action and send the component node a ref' do
                mock_translator.should_receive(:send_ami_action).once.with('ExtensionStatus', 'Context' => 'default', 'Exten' => 'idonno').and_return(RubyAMI::Response.new)
                subject.execute
                original_command.response(1).should == expected_response
              end
            end

            context 'when the AMI action completes' do
              let :response do
                RubyAMI::Response.new 'ActionID'  => '552a9d9f-46d7-45d8-a257-06fe95f48d99',
                                      'Message'   => 'Channel status will follow',
                                      'Exten'     => 'idonno',
                                      'Context'   => 'default',
                                      'Hint'      => '',
                                      'Status'    => '-1'
              end

              let :expected_complete_reason do
                Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => 'Channel status will follow', :attributes => {:exten => "idonno", :context => "default", :hint => "", :status => "-1"}
              end

              before { mock_translator.should_receive(:send_ami_action).once.and_return response }

              context 'for a non-causal action' do
                it 'should send a complete event to the component node' do
                  subject.wrapped_object.should_receive(:send_complete_event).once.with expected_complete_reason
                  subject.execute
                end
              end

              context 'for a causal action' do
                let :original_command do
                  Punchblock::Component::Asterisk::AMI::Action.new :name => 'CoreShowChannels'
                end

                let :expected_action do
                  RubyAMI::Action.new 'CoreShowChannels'
                end

                let :event do
                  RubyAMI::Event.new 'CoreShowChannel', 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
                    'Channel'          => 'SIP/127.0.0.1-00000013',
                    'UniqueID'         => '1287686437.19',
                    'Context'          => 'adhearsion',
                    'Extension'        => '23432',
                    'Priority'         => '2',
                    'ChannelState'     => '6',
                    'ChannelStateDesc' => 'Up'
                end

                let :terminating_event do
                  RubyAMI::Event.new 'CoreShowChannelsComplete', 'EventList' => 'Complete',
                    'ListItems' => '3',
                    'ActionID' => 'umtLtvSg-RN5n-GEay-Z786-YdiaSLNXkcYN'
                end

                let :event_node do
                  Punchblock::Event::Asterisk::AMI::Event.new :name => 'CoreShowChannel', :component_id => subject.id, :attributes => {
                    :channel          => 'SIP/127.0.0.1-00000013',
                    :uniqueid         => '1287686437.19',
                    :context          => 'adhearsion',
                    :extension        => '23432',
                    :priority         => '2',
                    :channelstate     => '6',
                    :channelstatedesc => 'Up'
                  }
                end

                let :expected_complete_reason do
                  Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => 'Channel status will follow', :attributes => {:exten => "idonno", :context => "default", :hint => "", :status => "-1", :eventlist => 'Complete', :listitems => '3'}
                end

                it 'should send events to the component node' do
                  event_node
                  original_command.register_handler :internal, Punchblock::Event::Asterisk::AMI::Event do |event|
                    @event = event
                  end
                  response.events << event << terminating_event
                  subject.execute
                  @event.should be == event_node
                end

                it 'should send a complete event to the component node' do
                  response.events << event << terminating_event

                  subject.execute

                  original_command.complete_event(0.5).reason.should be == expected_complete_reason
                end
              end

              context 'with an error' do
                let :response do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                let :expected_complete_reason do
                  Punchblock::Event::Complete::Error.new :details => 'Action failed', component_id: subject.id
                end

                it 'should send a complete event to the component node' do
                  expected_complete_reason
                  subject.execute
                  original_command.complete_event(0.5).reason.should be == expected_complete_reason
                end
              end
            end
          end
        end
      end
    end
  end
end
