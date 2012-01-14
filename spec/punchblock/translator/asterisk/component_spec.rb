require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Component do

      end

      module Component
        describe Component do
          let(:connection)  { Punchblock::Connection::Asterisk.new }
          let(:translator)  { connection.translator }
          let(:call)        { Punchblock::Translator::Asterisk::Call.new 'foo', translator }
          let(:command)     { Punchblock::Component::Input.new }

          subject { Component.new command, call }

          before { command.request! }

          describe "#send_event" do
            before { command.execute! }

            let :event do
              Punchblock::Event::Complete.new
            end

            let :expected_event do
              Punchblock::Event::Complete.new.tap do |e|
                e.call_id = call.id
                e.component_id = subject.id
              end
            end

            it "should send the event to the connection" do
              connection.expects(:handle_event).once.with expected_event
              subject.send_event event
            end

            context "when marked internal" do
              before { subject.internal = true }

              it "should add the event to the command" do
                command.expects(:add_event).once.with expected_event
                subject.send_event event
              end
            end
          end

          describe "#send_complete_event" do
            before { command.execute! }

            let(:reason) { Punchblock::Event::Complete::Stop.new }
            let :expected_event do
              Punchblock::Event::Complete.new.tap do |c|
                c.reason = Punchblock::Event::Complete::Stop.new
              end
            end

            it "should send a complete event with the specified reason" do
              subject.wrapped_object.expects(:send_event).once.with expected_event
              subject.send_complete_event reason
            end

            it "should cause the actor to be shut down" do
              subject.wrapped_object.stubs(:send_event).returns true
              subject.send_complete_event reason
              subject.should_not be_alive
            end
          end
        end
      end
    end
  end
end
