# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      describe Component do

      end

      module Component
        describe Component do
          let(:connection)  { Punchblock::Connection::Freeswitch.new }
          let(:translator)  { connection.translator }
          let(:call)        { Punchblock::Translator::Freeswitch::Call.new 'foo', translator }
          let(:command)     { Punchblock::Component::Input.new }

          subject { Component.new command, call }

          before { command.request! }

          describe '#handle_es_event' do
            context 'with a handler registered for a matching event' do
              let :es_event do
                RubyFS::Event.new nil, :event_name => 'CHANNEL_EXECUTE'
              end

              let(:response) { double 'Response' }

              it 'should execute the handler' do
                response.should_receive(:call).once.with es_event
                subject.register_handler :es, :event_name => 'CHANNEL_EXECUTE' do |event|
                  response.call event
                end
                subject.handle_es_event es_event
              end
            end
          end

          describe "#send_event" do
            before { command.execute! }

            let :event do
              Punchblock::Event::Complete.new
            end

            let :expected_event do
              Punchblock::Event::Complete.new target_call_id: call.id,
                component_id: subject.id
            end

            it "should send the event to the connection" do
              connection.should_receive(:handle_event).once.with expected_event
              subject.send_event event
            end
          end

          describe "#send_complete_event" do
            before { command.execute! }

            let(:reason) { Punchblock::Event::Complete::Stop.new }
            let :expected_event do
              Punchblock::Event::Complete.new reason: reason
            end

            it "should send a complete event with the specified reason" do
              subject.wrapped_object.should_receive(:send_event).once.with expected_event
              subject.send_complete_event reason
            end

            it "should cause the actor to be shut down" do
              subject.wrapped_object.stub(:send_event).and_return true
              subject.send_complete_event reason
              sleep 0.2
              subject.should_not be_alive
            end
          end

          describe "#call_ended" do
            it "should send a complete event with the call hangup reason" do
              subject.wrapped_object.should_receive(:send_complete_event).once.with Punchblock::Event::Complete::Hangup.new
              subject.call_ended
            end
          end

          describe "#application" do
            it "should execute a FS application on the current call" do
              call.should_receive(:application).once.with('appname', "%[punchblock_component_id=#{subject.id}]options")
              subject.application 'appname', 'options'
            end
          end

          describe '#execute_command' do
            before do
              component_command.request!
            end

            context 'with a command we do not understand' do
              let :component_command do
                Punchblock::Component::Stop.new :component_id => subject.id
              end

              it 'sends an error in response to the command' do
                subject.execute_command component_command
                component_command.response.should be == ProtocolError.new.setup('command-not-acceptable', "Did not understand command for component #{subject.id}", call.id, subject.id)
              end
            end
          end
        end
      end
    end
  end
end
