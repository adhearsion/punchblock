# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe ProtocolError do
    let(:name)          { :item_not_found }
    let(:text)          { 'Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]' }
    let(:call_id)       { 'f6d437f4-1e18-457b-99f8-b5d853f50347' }
    let(:component_id)  { 'abc123' }
    subject { ProtocolError.new.setup name, text, call_id, component_id }

    its(:inspect) { should be == '#<Punchblock::ProtocolError: name=:item_not_found text="Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]" call_id="f6d437f4-1e18-457b-99f8-b5d853f50347" component_id="abc123">' }

    describe ".exception" do
      context "with no arguments" do
        it "returns the original object" do
          ProtocolError.exception.should be == ProtocolError.new
        end
      end

      context "with self as the argument" do
        it "returns the original object" do
          ProtocolError.exception(subject).should be == ProtocolError.new(subject.to_s)
        end
      end

      context "with other values" do
        it "returns a new object with the appropriate values" do
          e = ProtocolError.exception 'FooBar'
          e.name.should == nil
          e.text.should == nil
          e.call_id.should == nil
          e.component_id.should == nil
        end
      end
    end

    describe "#exception" do
      context "with no arguments" do
        it "returns the original object" do
          subject.exception.should be subject
        end
      end

      context "with self as the argument" do
        it "returns the original object" do
          subject.exception(subject).should be subject
        end
      end

      context "with other values" do
        it "returns a new object with the appropriate values" do
          e = subject.exception("Boo")
          e.name.should == name
          e.text.should == text
          e.call_id.should == call_id
          e.component_id.should == component_id
        end
      end
    end

    describe "comparison" do
      context "with the same name, text, call ID and component ID" do
        let(:comparison) { ProtocolError.new.setup name, text, call_id, component_id }
        it { should be == comparison }
      end

      context "with a different name" do
        let(:comparison) { ProtocolError.new.setup :foo, text, call_id, component_id }
        it { should_not be == comparison }
      end

      context "with a different text" do
        let(:comparison) { ProtocolError.new.setup name, 'foo', call_id, component_id }
        it { should_not be == comparison }
      end

      context "with a different call ID" do
        let(:comparison) { ProtocolError.new.setup name, text, 'foo', component_id }
        it { should_not be == comparison }
      end

      context "with a different component ID" do
        let(:comparison) { ProtocolError.new.setup name, text, call_id, 'foo' }
        it { should_not be == comparison }
      end
    end
  end
end
