# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe Complete do
      it 'registers itself' do
        RayoNode.class_from_registration(:complete, 'urn:xmpp:rayo:ext:1').should be == Complete
      end

      describe "setting a reason" do
        let(:reason) { Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new }

        subject { described_class.new }

        before { subject.reason = reason }

        its(:reason) { should == reason }
      end

      describe "comparing for equality" do
        subject do
          Complete.new.tap do |c|
            c.reason          = Complete::Stop.new
            c.target_call_id  = '1234'
            c.component_id    = 'abcd'
          end
        end

        let :other_complete do
          Complete.new.tap do |c|
            c.reason          = reason
            c.target_call_id  = call_id
            c.component_id    = component_id
          end
        end

        context 'with reason, call id and component id the same' do
          let(:reason)        { Complete::Stop.new }
          let(:call_id)       { '1234' }
          let(:component_id)  { 'abcd' }

          it "should be equal" do
            subject.should be == other_complete
          end
        end

        context 'with a different reason' do
          let(:reason)        { Complete::Hangup.new }
          let(:call_id)       { '1234' }
          let(:component_id)  { 'abcd' }

          it "should not be equal" do
            subject.should_not be == other_complete
          end
        end

        context 'with a different call id' do
          let(:reason)        { Complete::Stop.new }
          let(:call_id)       { '5678' }
          let(:component_id)  { 'abcd' }

          it "should not be equal" do
            subject.should_not be == other_complete
          end
        end

        context 'with a different component id' do
          let(:reason)        { Complete::Stop.new }
          let(:call_id)       { '1234' }
          let(:component_id)  { 'efgh' }

          it "should not be equal" do
            subject.should_not be == other_complete
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <finish xmlns='urn:xmpp:rayo:output:complete:1' />
</complete>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Complete }

        it_should_behave_like 'event'

        its(:reason) { should be_instance_of Component::Output::Complete::Finish }
      end
    end

    describe Complete::Stop do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <stop xmlns='urn:xmpp:rayo:ext:complete:1' />
</complete>
        MESSAGE
      end

      subject { RayoNode.import(parse_stanza(stanza).root).reason }

      it { should be_instance_of Complete::Stop }

      its(:name) { should be == :stop }
    end

    describe Complete::Hangup do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <hangup xmlns='urn:xmpp:rayo:ext:complete:1' />
</complete>
        MESSAGE
      end

      subject { RayoNode.import(parse_stanza(stanza).root).reason }

      it { should be_instance_of Complete::Hangup }

      its(:name) { should be == :hangup }
    end

    describe Complete::Error do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <error xmlns='urn:xmpp:rayo:ext:complete:1'>
    Something really bad happened
  </error>
</complete>
        MESSAGE
      end

      subject { RayoNode.import(parse_stanza(stanza).root).reason }

      it { should be_instance_of Complete::Error }

      its(:name) { should be == :error }
      its(:details) { should be == "Something really bad happened" }

      describe "when setting options in initializer" do
        subject do
          Complete::Error.new :details => 'Ooops'
        end

        its(:details) { should be == 'Ooops' }
      end
    end
  end
end # Punchblock
