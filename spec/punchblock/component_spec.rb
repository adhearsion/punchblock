require 'spec_helper'

%w{
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Component
    describe ComponentNode do
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

        it "should set the original component on the event" do
          add_event
          event.original_component.should == subject
        end

        describe "with a complete event" do
          it "should set the complete event resource" do
            add_event
            subject.complete_event.set_yet?.should == true
            subject.complete_event.resource.should == event
          end

          it "should call #complete!" do
            subject.expects(:complete!).once
            add_event
          end
        end

        describe "with another event" do
          let(:event) { Event::Answered.new }

          it "should not set the complete event resource" do
            add_event
            subject.complete_event.set_yet?.should == false
          end
        end

        describe "with an event handler set" do
          let(:handler) { mock 'Response' }

          before do
            handler.expects(:call).once.with(event)
            subject.register_event_handler { |event| handler.call event }
          end

          it "should trigger the callback" do
            add_event
          end
        end
      end # #add_event

      describe "#response=" do
        before do
          subject.request!
          subject.client = Client.new
        end

        let(:component_id) { 'abc123' }

        let :ref do
          Ref.new.tap do |ref|
            ref.id = component_id
          end
        end

        it "should set the component ID from the ref" do
          subject.response = ref
          subject.component_id.should == component_id
          subject.client.find_component_by_id(component_id).should be subject
        end
      end
    end # ComponentNode
  end # Component
end # Punchblock
