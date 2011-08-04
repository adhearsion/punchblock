require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        describe Output do
          it 'registers itself' do
            RayoNode.class_from_registration(:output, 'urn:xmpp:rayo:output:1').should == Output
          end

          describe "when setting options in initializer" do
            subject do
              Output.new  :interrupt_on     => :speech,
                          :start_offset     => 2000,
                          :start_paused     => false,
                          :repeat_interval  => 2000,
                          :repeat_times     => 10,
                          :max_time         => 30000,
                          :voice            => 'allison'
            end

            its(:interrupt_on)     { should == :speech }
            its(:start_offset)     { should == 2000 }
            its(:start_paused)     { should == false }
            its(:repeat_interval)  { should == 2000 }
            its(:repeat_times)     { should == 10 }
            its(:max_time)         { should == 30000 }
            its(:voice)            { should == 'allison' }
          end

          describe "for audio" do
            subject { Output.new :audio => {:url => 'http://whatever.you-output-boss.com'} }

            it { RayoNode.import(subject.children.first).should == Audio.new(:url => 'http://whatever.you-output-boss.com') }
          end

          describe "for text" do
            subject { Output.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

            its(:voice) { should == 'kate' }
            its(:text) { should == 'Once upon a time there was a message...' }
          end

          describe "for SSML" do
            subject { Output.new :ssml => '<output-as interpret-as="ordinal">100</output-as>', :voice => 'kate' }

            its(:voice) { should == 'kate' }
            it "should have the correct content" do
              subject.child.to_s.should == '<output-as interpret-as="ordinal">100</output-as>'
            end
          end

          describe "actions" do
            let(:command) { Output.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

            before do
              command.command_id = 'abc123'
              command.call_id = '123abc'
              command.connection = Connection.new :username => '123', :password => '123'
            end

            describe '#pause_action' do
              subject { command.pause_action }

              its(:to_xml) { should == '<pause xmlns="urn:xmpp:rayo:output:1"/>' }
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
                  lambda { command.pause! }.should raise_error(InvalidActionError, "Cannot pause a Output that is not executing.")
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

              its(:to_xml) { should == '<resume xmlns="urn:xmpp:rayo:output:1"/>' }
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
                  lambda { command.resume! }.should raise_error(InvalidActionError, "Cannot resume a Output that is not paused.")
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
                  lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Output that is not executing.")
                end
              end
            end # #stop!

            describe "seeking" do
              let(:seek_options) { {:direction => :forward, :amount => 1500} }

              describe '#seek_action' do
                subject { command.seek_action seek_options }

                its(:to_xml) { should == '<seek xmlns="urn:xmpp:rayo:output:1" direction="forward" amount="1500"/>' }
                its(:command_id) { should == 'abc123' }
                its(:call_id) { should == '123abc' }
              end

              describe '#seek!' do
                describe "when not seeking" do
                  before do
                    command.request!
                    command.execute!
                  end

                  it "should send its command properly" do
                    seek_action = command.seek_action seek_options
                    command.stubs(:seek_action).returns seek_action
                    Connection.any_instance.expects(:write).with('123abc', seek_action, 'abc123').returns true
                    command.expects :seeking!
                    command.expects :stopped_seeking!
                    command.seek! seek_options
                    seek_action.request!
                    seek_action.execute!
                  end
                end

                describe "when seeking" do
                  before { command.seeking! }

                  it "should raise an error" do
                    lambda { command.seek! }.should raise_error(InvalidActionError, "Cannot seek an Output that is already seeking.")
                  end
                end
              end

              describe "#seeking!" do
                before do
                  subject.request!
                  subject.execute!
                  subject.seeking!
                end

                its(:seek_status_name) { should == :seeking }

                it "should raise a StateMachine::InvalidTransition when received a second time" do
                  lambda { subject.seeking! }.should raise_error(StateMachine::InvalidTransition)
                end
              end

              describe "#stopped_seeking!" do
                before do
                  subject.request!
                  subject.execute!
                  subject.seeking!
                  subject.stopped_seeking!
                end

                its(:seek_status_name) { should == :not_seeking }

                it "should raise a StateMachine::InvalidTransition when received a second time" do
                  lambda { subject.stopped_seeking! }.should raise_error(StateMachine::InvalidTransition)
                end
              end
            end

            # <!-- Increase playback speed -->
            # <iq type='set' to='9f00061@call.rayo.net/fgh4590' from='16577@app.rayo.net/1'>
            #   <speed-up xmlns='urn:xmpp:rayo:output:1' />
            # </iq>
            #
            # <!-- Decrease playback speed -->
            # <iq type='set' to='9f00061@call.rayo.net/fgh4590' from='16577@app.rayo.net/1'>
            #   <speed-down xmlns='urn:xmpp:rayo:output:1' />
            # </iq>
            #
            # <!-- Increase playback volume -->
            # <iq type='set' to='9f00061@call.rayo.net/fgh4590' from='16577@app.rayo.net/1'>
            #   <volume-up xmlns='urn:xmpp:rayo:output:1' />
            # </iq>
            #
            # <!-- Decrease playback volume -->
            # <iq type='set' to='9f00061@call.rayo.net/fgh4590' from='16577@app.rayo.net/1'>
            #   <volume-down xmlns='urn:xmpp:rayo:output:1' />
            # </iq>
          end
        end

        describe Output::Complete::Success do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
    <success xmlns='urn:xmpp:rayo:output:complete:1' />
  </complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Output::Complete::Success }

          its(:name) { should == :success }
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
