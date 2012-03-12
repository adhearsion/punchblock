# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe ProtocolError do
    let(:name)          { :item_not_found }
    let(:text)          { 'Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]' }
    let(:call_id)       { 'f6d437f4-1e18-457b-99f8-b5d853f50347' }
    let(:component_id)  { 'abc123' }
    subject { ProtocolError.new name, text, call_id, component_id }

    its(:inspect) { should == '#<Punchblock::ProtocolError: name=:item_not_found text="Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]" call_id="f6d437f4-1e18-457b-99f8-b5d853f50347" component_id="abc123">' }

    describe "comparison" do
      context "with the same name, text, call ID and component ID" do
        let(:comparison) { ProtocolError.new name, text, call_id, component_id }
        it { should == comparison }
      end

      context "with a different name" do
        let(:comparison) { ProtocolError.new :foo, text, call_id, component_id }
        it { should_not == comparison }
      end

      context "with a different text" do
        let(:comparison) { ProtocolError.new name, 'foo', call_id, component_id }
        it { should_not == comparison }
      end

      context "with a different call ID" do
        let(:comparison) { ProtocolError.new name, text, 'foo', component_id }
        it { should_not == comparison }
      end

      context "with a different component ID" do
        let(:comparison) { ProtocolError.new name, text, call_id, 'foo' }
        it { should_not == comparison }
      end
    end
  end
end
