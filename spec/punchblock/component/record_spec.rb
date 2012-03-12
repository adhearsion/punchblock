# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Record do
      it 'registers itself' do
        RayoNode.class_from_registration(:record, 'urn:xmpp:rayo:record:1').should be == Record
      end

      describe "when setting options in initializer" do
        subject do
          Record.new :format          => 'WAV',
                     :start_beep      => true,
                     :start_paused    => false,
                     :stop_beep       => true,
                     :max_duration    => 500000,
                     :initial_timeout => 10000,
                     :final_timeout   => 30000
        end

        its(:format)          { should be == 'WAV' }
        its(:start_beep)      { should be == true }
        its(:start_paused)    { should be == false }
        its(:stop_beep)       { should be == true }
        its(:max_duration)    { should be == 500000 }
        its(:initial_timeout) { should be == 10000 }
        its(:final_timeout)   { should be == 30000 }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<record xmlns="urn:xmpp:rayo:record:1"
        format="WAV"
        start-beep="true"
        start-paused="false"
        stop-beep="true"
        max-duration="500000"
        initial-timeout="10000"
        final-timeout="30000"/>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Record }

        its(:format)          { should be == 'WAV' }
        its(:start_beep)      { should be == true }
        its(:start_paused)    { should be == false }
        its(:stop_beep)       { should be == true }
        its(:max_duration)    { should be == 500000 }
        its(:initial_timeout) { should be == 10000 }
        its(:final_timeout)   { should be == 30000 }
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { Record.new }

        before do
          command.component_id = 'abc123'
          command.call_id = '123abc'
          command.client = mock_client
        end

        describe '#pause_action' do
          subject { command.pause_action }

          its(:to_xml) { should be == '<pause xmlns="urn:xmpp:rayo:record:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:call_id) { should be == '123abc' }
        end

        describe '#pause!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.pause_action, :call_id => '123abc', :component_id => 'abc123').returns true
              command.expects :paused!
              command.pause!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.pause! }.should raise_error(InvalidActionError, "Cannot pause a Record that is not executing")
            end
          end
        end

        describe "#paused!" do
          before do
            subject.request!
            subject.execute!
            subject.paused!
          end

          its(:state_name) { should be == :paused }

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            lambda { subject.paused! }.should raise_error(StateMachine::InvalidTransition)
          end
        end

        describe '#resume_action' do
          subject { command.resume_action }

          its(:to_xml) { should be == '<resume xmlns="urn:xmpp:rayo:record:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:call_id) { should be == '123abc' }
        end

        describe '#resume!' do
          describe "when the command is paused" do
            before do
              command.request!
              command.execute!
              command.paused!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.resume_action, :call_id => '123abc', :component_id => 'abc123').returns true
              command.expects :resumed!
              command.resume!
            end
          end

          describe "when the command is not paused" do
            it "should raise an error" do
              lambda { command.resume! }.should raise_error(InvalidActionError, "Cannot resume a Record that is not paused.")
            end
          end
        end

        describe "#resumed!" do
          before do
            subject.request!
            subject.execute!
            subject.paused!
            subject.resumed!
          end

          its(:state_name) { should be == :executing }

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            lambda { subject.resumed! }.should raise_error(StateMachine::InvalidTransition)
          end
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should be == '<stop xmlns="urn:xmpp:rayo:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:call_id) { should be == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.stop_action, :call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Record that is not executing")
            end
          end
        end
      end

      describe Record::Complete::Success do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<success xmlns='urn:xmpp:rayo:record:complete:1'/>
<recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3" duration="34000" size="23450"/>
</complete>
          MESSAGE
        end

        describe "#reason" do
          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Record::Complete::Success }

          its(:name)  { should be == :success }
        end

        describe "#recording" do
          subject { RayoNode.import(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }
          its(:uri)       { should be == "file:/tmp/rayo7451601434771683422.mp3" }
          its(:duration)  { should be == 34000 }
          its(:size)      { should be == 23450 }
        end
      end

      describe Event::Complete::Stop do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<stop xmlns='urn:xmpp:rayo:ext:complete:1' />
<recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3"/>
</complete>
          MESSAGE
        end

        describe "#reason" do
          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Event::Complete::Stop }

          its(:name)  { should be == :stop }
        end

        describe "#recording" do
          subject { RayoNode.import(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }
          its(:uri) { should be == "file:/tmp/rayo7451601434771683422.mp3" }
        end
      end

      describe Event::Complete::Hangup do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<hangup xmlns='urn:xmpp:rayo:ext:complete:1' />
<recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3"/>
</complete>
          MESSAGE
        end

        describe "#reason" do
          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Event::Complete::Hangup }

          its(:name)  { should be == :hangup }
        end

        describe "#recording" do
          subject { RayoNode.import(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }
          its(:uri) { should be == "file:/tmp/rayo7451601434771683422.mp3" }
        end
      end
    end
  end
end # Punchblock
