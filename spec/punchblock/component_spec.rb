require 'spec_helper'

%w{
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Component
    describe ComponentNode do
      its(:event_queue) { should be_empty }

      it "should not initially have a complete event set" do
        subject.complete_event.set_yet?.should == false
      end

      describe "#add_event" do
        let(:event) { Event::Complete.new }

        before do
          subject.request!
          subject.execute!
        end

        let(:add_event) { subject.add_event event }

        it "should add the event to the component's event queue" do
          add_event
          subject.event_queue.pop(false).should == event
        end

        it "should set the original event on the command" do
          add_event
          event.original_component.should == subject
        end

        it "should trigger state transition" do
          subject.expects(:transition_state!).once.with event
          add_event
        end

        describe "with a complete event" do
          it "should set the complete event resource" do
            add_event
            subject.complete_event.set_yet?.should == true
            subject.complete_event.resource.should == event
          end
        end

        describe "with another event" do
          let(:event) { Event::Answered.new }

          it "should not set the complete event resource" do
            add_event
            subject.complete_event.set_yet?.should == false
          end
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

      describe "#response=" do
        before do
          subject.request!
          subject.connection = mock(:record_command_id_for_iq_id => true)
        end

        let(:component_id) { 'abc123' }

        let :ref do
          Ref.new.tap do |ref|
            ref.id = component_id
          end
        end

        let :iq do
          Blather::Stanza::Iq.new(:result, 'blah').tap do |iq|
            iq.from = "12345@call.rayo.net"
            iq << ref
          end
        end

        it "should set the component ID from the ref" do
          subject.response = iq
          subject.component_id.should == component_id
        end
      end
    end # ComponentNode
  end # Component
end # Punchblock
