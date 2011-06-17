require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Command
        describe Say do
          it 'registers itself' do
            OzoneNode.class_from_registration(:say, 'urn:xmpp:ozone:say:1').should == Say
          end

          describe "for audio" do
            subject { Say.new :url => 'http://whatever.you-say-boss.com' }

            its(:audio) { should == Audio.new(:url => 'http://whatever.you-say-boss.com') }
          end

          describe "for text" do
            subject { Say.new :text => 'Once upon a time there was a message...', :voice => 'kate', :url => nil }

            its(:voice) { should == 'kate' }
            its(:text) { should == 'Once upon a time there was a message...' }
            its(:audio) { should == nil }
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

            before { command.command_id = 'abc123' }

            describe '#pause!' do
              subject { command.pause! }

              describe "when the command is executing" do
                before do
                  command.request!
                  command.execute!
                end

                its(:to_xml) { should == '<pause xmlns="urn:xmpp:ozone:say:1"/>' }
                its(:command_id) { should == 'abc123' }
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

            describe '#resume!' do
              subject { command.resume! }

              describe "when the command is paused" do
                before do
                  command.request!
                  command.execute!
                  command.paused!
                end

                its(:to_xml) { should == '<resume xmlns="urn:xmpp:ozone:say:1"/>' }
                its(:command_id) { should == 'abc123' }
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

            describe '#stop!' do
              subject { command.stop! }

              describe "when the command is executing" do
                before do
                  command.request!
                  command.execute!
                end

                its(:to_xml) { should == '<stop xmlns="urn:xmpp:ozone:say:1"/>' }
                its(:command_id) { should == 'abc123' }
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Say that is not executing.")
                end
              end
            end
          end
        end

        describe Say::Complete::Success do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <success xmlns='urn:xmpp:ozone:say:complete:1' />
  </complete>
            MESSAGE
          end

          subject { OzoneNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Say::Complete::Success }

          its(:name) { should == :success }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
