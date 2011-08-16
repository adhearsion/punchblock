require 'spec_helper'

module Punchblock
  class Rayo
    module Component
      describe ComponentNode do
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
            event.original_component.should == subject
          end

          it "should trigger state transition" do
            subject.expects(:transition_state!).once.with event
            subject.add_event event
          end
        end # #add_event

        describe "#transition_state!" do
          describe "with a complete" do
            it "should call #complete!" do
              subject.expects(:complete!).once
              subject.transition_state! Event::Complete.new
            end
          end
        end # #transition_state!
      end # ComponentNode
    end # Component
  end # Rayo
end # Punchblock
