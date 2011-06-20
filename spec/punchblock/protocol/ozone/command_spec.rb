require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Command
        describe CommandNode do
          its(:events) { should == [] }

          describe "#add_event" do
            let(:event) { Event::Complete.new }

            before do
              subject.request!
              subject.execute!
            end

            let(:add_event) { subject.add_event event }

            it "should add the event to the command's events" do
              add_event
              subject.events.should == [event]
            end

            it "should set the original event on the command" do
              add_event
              event.original_command.should == subject
            end

            it "should trigger state transition" do
              subject.expects(:transition_state!).once.with event
              subject.add_event event
            end
          end # #add_event

          its(:state_name) { should == :new }

          describe "#transition_state!" do
            describe "with a complete" do
              it "should call #complete!" do
                subject.expects(:complete!).once
                subject.transition_state! Event::Complete.new
              end
            end
          end # #transition_state!

          describe "#request!" do
            before { subject.request! }

            its(:state_name) { should == :requested }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.request! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "#execute!" do
            describe "without sending" do
              it "should raise a StateMachine::InvalidTransition" do
                lambda { subject.execute! }.should raise_error(StateMachine::InvalidTransition)
              end
            end

            describe "after sending" do
              before do
                subject.request!
                subject.execute!
              end

              its(:state_name) { should == :executing }
            end
          end

          describe "#complete!" do
            before do
              subject.request!
              subject.execute!
              subject.complete!
            end

            its(:state_name) { should == :complete }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.complete! }.should raise_error(StateMachine::InvalidTransition)
            end
          end # #complete!
        end # CommandNode
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
