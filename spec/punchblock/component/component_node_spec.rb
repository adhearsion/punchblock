# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe ComponentNode do
      it { should be_new }

      describe "#add_event" do
        let(:event) { Event::Complete.new }

        before do
          subject.request!
          subject.execute!
        end

        let(:add_event) { subject.add_event event }

        describe "with a complete event" do
          it "should set the complete event resource" do
            add_event
            subject.complete_event(0.5).should be == event
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
            subject.should_not be_complete
          end
        end
      end # #add_event

      describe "#trigger_event_handler" do
        let(:event) { Event::Complete.new }

        before do
          subject.request!
          subject.execute!
        end

        describe "with an event handler set" do
          let(:handler) { mock 'Response' }

          before do
            handler.expects(:call).once.with(event)
            subject.register_event_handler { |event| handler.call event }
          end

          it "should trigger the callback" do
            subject.trigger_event_handler event
          end
        end
      end # #trigger_event_handler

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
          subject.component_id.should be == component_id
          subject.client.find_component_by_id(component_id).should be subject
        end
      end

      describe "#complete_event=" do
        before do
          subject.request!
          subject.execute!
        end

        it "should set the command to executing status" do
          subject.complete_event = :foo
          subject.should be_complete
        end

        it "should be a no-op if the response has already been set" do
          subject.complete_event = :foo
          lambda { subject.complete_event = :bar }.should_not raise_error
          subject.complete_event(0.5).should be == :foo
        end
      end
    end # ComponentNode
  end # Component
end # Punchblock
