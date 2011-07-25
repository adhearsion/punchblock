require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Record do
          it 'registers itself' do
            RayoNode.class_from_registration(:record, 'urn:xmpp:rayo:record:1').should == Record
          end

          describe "when setting options in initializer" do
            subject do
              Record.new :bargein           => true,
                         :codec             => 'AMR',
                         :codec_params      => 'bitrate=5.3;annexa=no',
                         :dtmf_truncate     => true,
                         :final_timeout     => 30000,
                         :format            => 'WAV',
                         :initial_timeout   => 10000,
                         :min_length        => -1,
                         :max_length        => 500000,
                         :sample_rate       => 16000,
                         :silence_terminate => false,
                         :start_beep        => true,
                         :start_pause_mode  => false
            end

            its(:bargein)           { should == true }
            its(:codec)             { should == 'AMR' }
            its(:codec_params)      { should == 'bitrate=5.3;annexa=no' }
            its(:dtmf_truncate)     { should == true }
            its(:final_timeout)     { should == 30000 }
            its(:format)            { should == 'WAV' }
            its(:initial_timeout)   { should == 10000 }
            its(:min_length)        { should == -1 }
            its(:max_length)        { should == 500000 }
            its(:sample_rate)       { should == 16000 }
            its(:silence_terminate) { should == false }
            its(:start_beep)        { should == true }
            its(:start_pause_mode)  { should == false }
          end

          describe "actions" do
            let(:command) { Record.new }

            before do
              command.command_id = 'abc123'
              command.call_id = '123abc'
              command.connection = Connection.new :username => '123', :password => '123'
            end

            describe '#pause_action' do
              subject { command.pause_action }

              its(:to_xml) { should == '<pause xmlns="urn:xmpp:rayo:record:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#pause!' do
              describe "when the command is executing" do
                before do
                  command.request!
                  command.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', command.pause_action, 'abc123').returns true
                  command.expects :paused!
                  command.pause!
                end
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { command.pause! }.should raise_error(InvalidActionError, "Cannot pause a Record that is not executing.")
                end
              end
            end

            describe "#paused!" do
              before do
                subject.request!
                subject.execute!
                subject.paused!
              end

              its(:state_name) { should == :paused }

              it "should raise a StateMachine::InvalidTransition when received a second time" do
                lambda { subject.paused! }.should raise_error(StateMachine::InvalidTransition)
              end
            end

            describe '#resume_action' do
              subject { command.resume_action }

              its(:to_xml) { should == '<resume xmlns="urn:xmpp:rayo:record:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#resume!' do
              describe "when the command is paused" do
                before do
                  command.request!
                  command.execute!
                  command.paused!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', command.resume_action, 'abc123').returns true
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

              its(:state_name) { should == :executing }

              it "should raise a StateMachine::InvalidTransition when received a second time" do
                lambda { subject.resumed! }.should raise_error(StateMachine::InvalidTransition)
              end
            end

            describe '#stop_action' do
              subject { command.stop_action }

              its(:to_xml) { should == '<stop xmlns="urn:xmpp:rayo:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#stop!' do
              describe "when the command is executing" do
                before do
                  command.request!
                  command.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', command.stop_action, 'abc123')
                  command.stop!
                end
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Record that is not executing.")
                end
              end
            end
          end

          describe Record::Complete::Success do
            let :stanza do
              <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:rayo:record:complete:1'/>
  <recording xmlns='urn:xmpp:rayo:record:complete:1' uri="file:/tmp/rayo7451601434771683422.mp3"/>
</complete>
              MESSAGE
            end

            describe "#reason" do
              subject { RayoNode.import(parse_stanza(stanza).root).reason }

              it { should be_instance_of Record::Complete::Success }

              its(:name)  { should == :success }
            end

            describe "#recording" do
              subject { RayoNode.import(parse_stanza(stanza).root).recording }

              it { should be_instance_of Record::Recording }
              its(:uri) { should == "file:/tmp/rayo7451601434771683422.mp3" }
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

              its(:name)  { should == :stop }
            end

            describe "#recording" do
              subject { RayoNode.import(parse_stanza(stanza).root).recording }

              it { should be_instance_of Record::Recording }
              its(:uri) { should == "file:/tmp/rayo7451601434771683422.mp3" }
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

              its(:name)  { should == :hangup }
            end

            describe "#recording" do
              subject { RayoNode.import(parse_stanza(stanza).root).recording }

              it { should be_instance_of Record::Recording }
              its(:uri) { should == "file:/tmp/rayo7451601434771683422.mp3" }
            end
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
