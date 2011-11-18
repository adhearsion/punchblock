require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AMIAction do
            let(:mock_translator) { mock 'Translator::Asterisk' }

            let :command do
              Punchblock::Component::Asterisk::AMI::Action.new :name => 'ExtensionStatus', :params => { :context => 'default', :exten => 'idonno' }
            end

            subject { AMIAction.new command, mock_translator }

            let :expected_action do
              RubyAMI::Action.new 'ExtensionStatus', 'Context' => 'default', 'Exten' => 'idonno'
            end

            context 'initial execution' do
              let(:component_id) { UUIDTools::UUID.random_create }

              let :expected_response do
                Ref.new :id => component_id
              end

              before { UUIDTools::UUID.stubs :random_create => component_id }

              it 'should send the appropriate RubyAMI::Action and send the component node a ref with the action ID' do
                mock_translator.expects(:send_ami_action!).once.with(expected_action).returns(expected_action)
                command.expects(:response=).once.with(expected_response)
                subject.execute
              end
            end

            context 'when the AMI action completes' do
              before do
                command.request!
                command.execute!
              end

              let :response do
                RubyAMI::Response.new.tap do |r|
                  r['ActionID'] = "552a9d9f-46d7-45d8-a257-06fe95f48d99"
                  r['Message']  = 'Channel status will follow'
                  r["Exten"]    = "idonno"
                  r["Context"]  = "default"
                  r["Hint"]     = ""
                  r["Status"]   = "-1"
                end
              end

              let :expected_complete_reason do
                Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => 'Channel status will follow', :attributes => {:exten => "idonno", :context => "default", :hint => "", :status => "-1"}
              end

              context 'for a non-causal action' do
                it 'should send a complete event to the component node' do
                  subject.action.response = response

                  command.should be_complete

                  complete_event = command.complete_event 0.5

                  complete_event.component_id.should == subject.id
                  complete_event.reason.should == expected_complete_reason
                end
              end

              context 'for a causal action' do
                let :command do
                  Punchblock::Component::Asterisk::AMI::Action.new :name => 'CoreShowChannels'
                end

                let :expected_action do
                  RubyAMI::Action.new 'CoreShowChannels'
                end

                let :event do
                  RubyAMI::Event.new('CoreShowChannel').tap do |e|
                    e['ActionID']         = "552a9d9f-46d7-45d8-a257-06fe95f48d99"
                    e['Channel']          = 'SIP/127.0.0.1-00000013'
                    e['UniqueID']         = '1287686437.19'
                    e['Context']          = 'adhearsion'
                    e['Extension']        = '23432'
                    e['Priority']         = '2'
                    e['ChannelState']     = '6'
                    e['ChannelStateDesc'] = 'Up'
                  end
                end

                let :terminating_event do
                  RubyAMI::Event.new('CoreShowChannelsComplete').tap do |e|
                    e['EventList'] = 'Complete'
                    e['ListItems'] = '3'
                    e['ActionID'] = 'umtLtvSg-RN5n-GEay-Z786-YdiaSLNXkcYN'
                  end
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
                  command.register_event_handler Punchblock::Event::Asterisk::AMI::Event do |event|
                    @event = event
                  end
                  subject.action << event
                  subject.action << response
                  subject.action << terminating_event
                  @event.should == event_node
                end

                it 'should send a complete event to the component node' do
                  subject.action << response
                  subject.action << terminating_event

                  command.complete_event(0.5).reason.should == expected_complete_reason
                end
              end

              context 'with an error' do
                let :error do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                let :expected_complete_reason do
                  Punchblock::Event::Complete::Error.new :component_id => subject.id, :details => 'Action failed'
                end

                it 'should send a complete event to the component node' do
                  subject.action << error

                  complete_event = command.complete_event 0.5

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
