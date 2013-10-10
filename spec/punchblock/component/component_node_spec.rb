# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe ComponentNode do
      subject do
        Class.new(described_class) { register 'foo'}.new
      end

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
            subject.should_receive(:complete!).once
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
          let(:handler) { double 'Response' }

          before do
            handler.should_receive(:call).once.with(event)
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
          Ref.new uri: component_id
        end

        it "should set the component ID from the ref" do
          subject.response = ref
          subject.component_id.should be == component_id
          subject.client.find_component_by_key(component_id).should be subject
        end
      end

      describe "#complete_event=" do
        before do
          subject.request!
          subject.client = Client.new
          subject.response = Ref.new uri: 'abc'
          subject.client.find_component_by_key('abc').should be subject
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

        it "should remove the component from the registry" do
          subject.complete_event = :foo
          subject.client.find_component_by_key('abc').should be_nil
        end
      end
    end # ComponentNode
  end # Component
end # Punchblock
