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
            expect(subject.complete_event(0.5)).to eq(event)
          end

          it "should call #complete!" do
            expect(subject).to receive(:complete!).once
            add_event
          end
        end

        describe "with another event" do
          let(:event) { Event::Answered.new }

          it "should not set the complete event resource" do
            add_event
            expect(subject).not_to be_complete
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
            expect(handler).to receive(:call).once.with(event)
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

        let(:uri) { 'xmpp:callid@server/abc123' }

        let :ref do
          Ref.new uri: uri
        end

        it "should set the component ID from the ref" do
          subject.response = ref
          expect(subject.component_id).to eq('abc123')
          expect(subject.source_uri).to eq(uri)
          expect(subject.client.find_component_by_uri(uri)).to be subject
        end
      end

      describe "#complete_event=" do
        before do
          subject.request!
          subject.client = Client.new
          subject.response = Ref.new uri: 'abc'
          expect(subject.client.find_component_by_uri('abc')).to be subject
        end

        it "should set the command to executing status" do
          subject.complete_event = :foo
          expect(subject).to be_complete
        end

        it "should be a no-op if the response has already been set" do
          subject.complete_event = :foo
          expect { subject.complete_event = :bar }.not_to raise_error
          expect(subject.complete_event(0.5)).to eq(:foo)
        end

        it "should remove the component from the registry" do
          subject.complete_event = :foo
          expect(subject.client.find_component_by_uri('abc')).to be_nil
        end
      end
    end # ComponentNode
  end # Component
end # Punchblock
