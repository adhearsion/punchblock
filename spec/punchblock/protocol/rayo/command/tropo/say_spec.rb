require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Command
        module Tropo
          describe Say do
            it 'registers itself' do
              RayoNode.class_from_registration(:say, 'urn:xmpp:rayo:say:1').should == Say
            end

            describe "for audio" do
              subject { Say.new :audio => {:url => 'http://whatever.you-say-boss.com'} }

              it { RayoNode.import(subject.children.first).should == Audio.new(:url => 'http://whatever.you-say-boss.com') }
            end

            describe "for text" do
              subject { Say.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

              its(:voice) { should == 'kate' }
              its(:text) { should == 'Once upon a time there was a message...' }
            end

            describe "for SSML" do
              subject { Say.new :ssml => '<say-as interpret-as="ordinal">100</say-as>', :voice => 'kate' }

              its(:voice) { should == 'kate' }
              it "should have the correct content" do
                subject.child.to_s.should == '<say-as interpret-as="ordinal">100</say-as>'
              end
            end

            describe "actions" do
              let(:command) { Say.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

              before do
                command.command_id = 'abc123'
                command.call_id = '123abc'
                command.connection = Connection.new :username => '123', :password => '123'
              end

              describe '#pause_action' do
                subject { command.pause_action }

                its(:to_xml) { should == '<pause xmlns="urn:xmpp:rayo:say:1"/>' }
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
                    lambda { command.pause! }.should raise_error(InvalidActionError, "Cannot pause a Say that is not executing.")
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

                its(:to_xml) { should == '<resume xmlns="urn:xmpp:rayo:say:1"/>' }
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
                    lambda { command.resume! }.should raise_error(InvalidActionError, "Cannot resume a Say that is not paused.")
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
                    lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Say that is not executing.")
                  end
                end
              end # #stop!
            end
          end

          describe Say::Complete::Success do
            let :stanza do
              <<-MESSAGE
    <complete xmlns='urn:xmpp:rayo:ext:1'>
      <success xmlns='urn:xmpp:rayo:say:complete:1' />
    </complete>
              MESSAGE
            end

            subject { RayoNode.import(parse_stanza(stanza).root).reason }

            it { should be_instance_of Say::Complete::Success }

            its(:name) { should == :success }
          end
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
