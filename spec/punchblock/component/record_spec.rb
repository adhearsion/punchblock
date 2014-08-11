# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Record do
      it 'registers itself' do
        expect(RayoNode.class_from_registration(:record, 'urn:xmpp:rayo:record:1')).to eq(described_class)
      end

      describe "when setting options in initializer" do
        subject(:command) do
          Record.new :format          => 'WAV',
                     :start_beep      => true,
                     :stop_beep       => false,
                     :start_paused    => false,
                     :max_duration    => 500000,
                     :initial_timeout => 10000,
                     :final_timeout   => 30000,
                     :direction       => :duplex,
                     :mix             => true
        end

        describe '#format' do
          subject { super().format }
          it { should be == 'WAV' }
        end

        describe '#start_beep' do
          subject { super().start_beep }
          it { should be == true }
        end

        describe '#stop_beep' do
          subject { super().stop_beep }
          it { should be == false }
        end

        describe '#start_paused' do
          subject { super().start_paused }
          it { should be == false }
        end

        describe '#max_duration' do
          subject { super().max_duration }
          it { should be == 500000 }
        end

        describe '#initial_timeout' do
          subject { super().initial_timeout }
          it { should be == 10000 }
        end

        describe '#final_timeout' do
          subject { super().final_timeout }
          it { should be == 30000 }
        end

        describe '#direction' do
          subject { super().direction }
          it { should be == :duplex }
        end

        describe '#mix' do
          subject { super().mix }
          it { should be == true }
        end

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            expect(new_instance).to be_instance_of described_class
            expect(new_instance.format).to eq('WAV')
            expect(new_instance.start_beep).to eq(true)
            expect(new_instance.stop_beep).to eq(false)
            expect(new_instance.start_paused).to eq(false)
            expect(new_instance.max_duration).to eq(500000)
            expect(new_instance.initial_timeout).to eq(10000)
            expect(new_instance.final_timeout).to eq(30000)
            expect(new_instance.direction).to eq(:duplex)
            expect(new_instance.mix).to eq(true)
          end

          it "should render to a parent node if supplied" do
            doc = Nokogiri::XML::Document.new
            parent = Nokogiri::XML::Node.new 'foo', doc
            doc.root = parent
            rayo_doc = subject.to_rayo(parent)
            expect(rayo_doc).to eq(parent)
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<record xmlns="urn:xmpp:rayo:record:1"
        format="WAV"
        start-beep="true"
        stop-beep="false"
        start-paused="false"
        max-duration="500000"
        initial-timeout="10000"
        direction="duplex"
        mix="true"
        final-timeout="30000"/>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Record }

        describe '#format' do
          subject { super().format }
          it { should be == 'WAV' }
        end

        describe '#start_beep' do
          subject { super().start_beep }
          it { should be == true }
        end

        describe '#stop_beep' do
          subject { super().stop_beep }
          it { should be == false }
        end

        describe '#start_paused' do
          subject { super().start_paused }
          it { should be == false }
        end

        describe '#max_duration' do
          subject { super().max_duration }
          it { should be == 500000 }
        end

        describe '#initial_timeout' do
          subject { super().initial_timeout }
          it { should be == 10000 }
        end

        describe '#final_timeout' do
          subject { super().final_timeout }
          it { should be == 30000 }
        end

        describe '#direction' do
          subject { super().direction }
          it { should be == :duplex }
        end

        describe '#mix' do
          subject { super().mix }
          it { should be == true }
        end
      end

      describe "with a direction" do
        [nil, :duplex, :send, :recv].each do |direction|
          describe direction do
            subject { described_class.new :direction => direction }

            describe '#direction' do
              subject { super().direction }
              it { should be == direction }
            end
          end
        end

        describe "no direction" do
          subject { Record.new }

          describe '#direction' do
            subject { super().direction }
            it { should be_nil }
          end
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { described_class.new(:direction => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end

      describe "actions" do
        let(:mock_client) { double 'Client' }
        let(:command) { described_class.new }

        before do
          command.component_id = 'abc123'
          command.target_call_id = '123abc'
          command.client = mock_client
        end

        describe '#pause_action' do
          subject { command.pause_action }

          describe '#to_xml' do
            subject { super().to_xml }
            it { should be == '<pause xmlns="urn:xmpp:rayo:record:1"/>' }
          end

          describe '#component_id' do
            subject { super().component_id }
            it { should be == 'abc123' }
          end

          describe '#target_call_id' do
            subject { super().target_call_id }
            it { should be == '123abc' }
          end
        end

        describe '#pause!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              expect(mock_client).to receive(:execute_command).with(command.pause_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
              expect(command).to receive :paused!
              command.pause!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              expect { command.pause! }.to raise_error(InvalidActionError, "Cannot pause a Record that is not executing")
            end
          end
        end

        describe "#paused!" do
          before do
            command.request!
            command.execute!
            command.paused!
          end

          describe '#state_name' do
            subject { command.state_name }
            it { should be == :paused }
          end

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            expect { subject.paused! }.to raise_error(StateMachine::InvalidTransition)
          end
        end

        describe '#resume_action' do
          subject { command.resume_action }

          describe '#to_xml' do
            subject { super().to_xml }
            it { should be == '<resume xmlns="urn:xmpp:rayo:record:1"/>' }
          end

          describe '#component_id' do
            subject { super().component_id }
            it { should be == 'abc123' }
          end

          describe '#target_call_id' do
            subject { super().target_call_id }
            it { should be == '123abc' }
          end
        end

        describe '#resume!' do
          describe "when the command is paused" do
            before do
              command.request!
              command.execute!
              command.paused!
            end

            it "should send its command properly" do
              expect(mock_client).to receive(:execute_command).with(command.resume_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
              expect(command).to receive :resumed!
              command.resume!
            end
          end

          describe "when the command is not paused" do
            it "should raise an error" do
              expect { command.resume! }.to raise_error(InvalidActionError, "Cannot resume a Record that is not paused.")
            end
          end
        end

        describe "#resumed!" do
          before do
            command.request!
            command.execute!
            command.paused!
            command.resumed!
          end

          describe '#state_name' do
            subject { command.state_name }
            it { should be == :executing }
          end

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            expect { subject.resumed! }.to raise_error(StateMachine::InvalidTransition)
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
                expect(subject.recording).to be_a Punchblock::Component::Record::Recording
              end
            end

            describe "#recording_uri" do
              it "should be the recording URI set earlier" do
                expect(subject.recording_uri).to eq("file:/tmp/rayo7451601434771683422.mp3")
              end
            end
          end

        describe '#stop_action' do
          subject { command.stop_action }

          describe '#to_xml' do
            subject { super().to_xml }
            it { should be == '<stop xmlns="urn:xmpp:rayo:ext:1"/>' }
          end

          describe '#component_id' do
            subject { super().component_id }
            it { should be == 'abc123' }
          end

          describe '#target_call_id' do
            subject { super().target_call_id }
            it { should be == '123abc' }
          end
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              expect(mock_client).to receive(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              expect { command.stop! }.to raise_error(InvalidActionError, "Cannot stop a Record that is new")
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

            describe '#name' do
              subject { super().name }
              it { should be == element_name }
            end
          end

          describe "#recording" do
            subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

            it { should be_instance_of Record::Recording }

            describe '#uri' do
              subject { super().uri }
              it { should be == "file:/tmp/rayo7451601434771683422.mp3" }
            end

            describe '#duration' do
              subject { super().duration }
              it { should be == 34000 }
            end

            describe '#size' do
              subject { super().size }
              it { should be == 23450 }
            end
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

          describe '#name' do
            subject { super().name }
            it { should be == :stop }
          end
        end

        describe "#recording" do
          subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }

          describe '#uri' do
            subject { super().uri }
            it { should be == "file:/tmp/rayo7451601434771683422.mp3" }
          end
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

          describe '#name' do
            subject { super().name }
            it { should be == :hangup }
          end
        end

        describe "#recording" do
          subject { RayoNode.from_xml(parse_stanza(stanza).root).recording }

          it { should be_instance_of Record::Recording }

          describe '#uri' do
            subject { super().uri }
            it { should be == "file:/tmp/rayo7451601434771683422.mp3" }
          end
        end
      end
    end
  end
end # Punchblock
