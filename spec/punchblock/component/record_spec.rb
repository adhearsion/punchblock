# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Record do
      it 'registers itself' do
        RayoNode.class_from_registration(:record, 'urn:xmpp:rayo:record:1').should be == described_class
      end

      describe "when setting options in initializer" do
        subject do
          Record.new :format          => 'WAV',
                     :start_beep      => true,
                     :start_paused    => false,
                     :max_duration    => 500000,
                     :initial_timeout => 10000,
                     :final_timeout   => 30000,
                     :direction       => :duplex
        end

        its(:format)          { should be == 'WAV' }
        its(:start_beep)      { should be == true }
        its(:start_paused)    { should be == false }
        its(:max_duration)    { should be == 500000 }
        its(:initial_timeout) { should be == 10000 }
        its(:final_timeout)   { should be == 30000 }
        its(:direction)       { should be == :duplex }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.format.should be == 'WAV'
            new_instance.start_beep.should be == true
            new_instance.start_paused.should be == false
            new_instance.max_duration.should be == 500000
            new_instance.initial_timeout.should be == 10000
            new_instance.final_timeout.should be == 30000
            new_instance.direction.should be == :duplex
          end

          it "should render to a parent node if supplied" do
            doc = Nokogiri::XML::Document.new
            parent = Nokogiri::XML::Node.new 'foo', doc
            doc.root = parent
            rayo_doc = subject.to_rayo(parent)
            rayo_doc.should == parent
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<record xmlns="urn:xmpp:rayo:record:1"
        format="WAV"
        start-beep="true"
        start-paused="false"
        max-duration="500000"
        initial-timeout="10000"
        direction="duplex"
        final-timeout="30000"/>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Record }

        its(:format)          { should be == 'WAV' }
        its(:start_beep)      { should be == true }
        its(:start_paused)    { should be == false }
        its(:max_duration)    { should be == 500000 }
        its(:initial_timeout) { should be == 10000 }
        its(:final_timeout)   { should be == 30000 }
        its(:direction)       { should be == :duplex }
      end

      describe "with a direction" do
        [nil, :duplex, :send, :recv].each do |direction|
          describe direction do
            subject { described_class.new :direction => direction }

            its(:direction) { should be == direction }
          end
        end

        describe "no direction" do
          subject { Record.new }

          its(:direction) { should be_nil }
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { described_class.new(:direction => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { described_class.new }

        before do
          command.component_id = 'abc123'
          command.target_call_id = '123abc'
          command.client = mock_client
        end

        describe '#pause_action' do
          subject { command.pause_action }

          its(:to_xml) { should be == '<pause xmlns="urn:xmpp:rayo:record:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#pause!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.should_receive(:execute_command).with(command.pause_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
              command.should_receive :paused!
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
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#resume!' do
          describe "when the command is paused" do
            before do
              command.request!
              command.execute!
              command.paused!
            end

            it "should send its command properly" do
              mock_client.should_receive(:execute_command).with(command.resume_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
              command.should_receive :resumed!
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

          context "direct recording accessors" do
            let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<success xmlns='urn:xmpp:rayo:record:complete:1'/>
<recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3" duration="34000" size="23450"/>
</complete>
          MESSAGE
            end
            let(:event) { RayoNode.from_xml(parse_stanza(stanza).root) }

            before do
              subject.request!
              subject.execute!
              subject.add_event event
            end

            describe "#recording" do
              it "should be a Punchblock::Component::Record::Recording" do
                subject.recording.should be_a Punchblock::Component::Record::Recording
              end
            end

            describe "#recording_uri" do
              it "should be the recording URI set earlier" do
                subject.recording_uri.should be == "file:/tmp/rayo7451601434771683422.mp3"
              end
            end
          end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should be == '<stop xmlns="urn:xmpp:rayo:ext:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.should_receive(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Record that is new")
            end
          end
        end
      end

      {
        Record::Complete::MaxDuration => :'max-duration',
        Record::Complete::InitialTimeout => :'initial-timeout',
        Record::Complete::FinalTimeout => :'final-timeout',
      }.each do |klass, element_name|
        describe klass do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <#{element_name} xmlns='urn:xmpp:rayo:record:complete:1'/>
  <recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3" duration="34000" size="23450"/>
  </complete>
            MESSAGE
          end

          describe "#reason" do
            subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

            it { should be_instance_of klass }

            its(:name)  { should be == element_name }
          end

          describe "#recording" do
            subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

            it { should be_instance_of Record::Recording }
            its(:uri)       { should be == "file:/tmp/rayo7451601434771683422.mp3" }
            its(:duration)  { should be == 34000 }
            its(:size)      { should be == 23450 }
          end
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
          subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

          it { should be_instance_of Event::Complete::Stop }

          its(:name)  { should be == :stop }
        end

        describe "#recording" do
          subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

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
          subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

          it { should be_instance_of Event::Complete::Hangup }

          its(:name)  { should be == :hangup }
        end

        describe "#recording" do
          subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }
          its(:uri) { should be == "file:/tmp/rayo7451601434771683422.mp3" }
        end
      end
    end
  end
end # Punchblock
