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
              subject.add_event event
            end

            it "should add the event to the command's events" do
              subject.events.should == [event]
            end

            it "should set the original event on the command" do
              event.original_command.should == subject
            end
          end
        end
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
