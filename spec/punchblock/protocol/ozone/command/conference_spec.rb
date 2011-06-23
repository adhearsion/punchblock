require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Command
        describe Conference do
          it 'registers itself' do
            OzoneNode.class_from_registration(:conference, 'urn:xmpp:ozone:conference:1').should == Conference
          end

          describe "when setting options in initializer" do
            subject do
              Conference.new :name              => '1234',
                             :terminator        => '#',
                             :moderator         => true,
                             :tone_passthrough  => true,
                             :mute              => false,
                             :announcement      => {:text => "Welcome to Ozone", :url => "http://it.doesnt.matter.does.it/?", :voice => 'shelly'},
                             :music             => {:text => "The moderator how not yet joined.. Listen to this awesome music while you wait.", :url => "http://www.yanni.com/music/awesome.mp3", :voice => 'frank'}
            end

            its(:name)              { should == '1234' }
            its(:mute)              { should == false }
            its(:terminator)        { should == '#' }
            its(:tone_passthrough)  { should == true }
            its(:moderator)         { should == true }
            its(:announcement)      { should == Conference::Announcement.new(:text => "Welcome to Ozone", :url => "http://it.doesnt.matter.does.it/?", :voice => 'shelly') }
            its(:music)             { should == Conference::Music.new(:text => "The moderator how not yet joined.. Listen to this awesome music while you wait.", :url => "http://www.yanni.com/music/awesome.mp3", :voice => 'frank') }
          end

          its(:mute_status_name) { should == :unmuted }
          its(:hold_status_name) { should == :unknown }

          describe "#transition_state!" do
            describe "with an on-hold" do
              it "should call #onhold!" do
                subject.expects(:onhold!).once
                subject.transition_state! Conference::OnHold.new
              end
            end

            describe "with an off-hold" do
              it "should call #offhold!" do
                subject.expects(:offhold!).once
                subject.transition_state! Conference::OffHold.new
              end
            end
          end # #transition_state!

          describe "#onhold!" do
            before do
              subject.onhold!
            end

            its(:hold_status_name) { should == :onhold }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.onhold! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "#offhold!" do
            before do
              subject.onhold!
              subject.offhold!
            end

            its(:hold_status_name) { should == :offhold }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.offhold! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "actions" do
            let(:conference) { Conference.new :name => '1234' }

            before do
              conference.command_id = 'abc123'
              conference.call_id = '123abc'
              conference.connection = Connection.new :username => '123', :password => '123'
            end

            describe '#mute_action' do
              subject { conference.mute_action }

              its(:to_xml) { should == '<mute xmlns="urn:xmpp:ozone:conference:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#mute!' do
              describe "when unmuted" do
                before do
                  conference.request!
                  conference.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', conference.mute_action, 'abc123').returns true
                  conference.expects :muted!
                  conference.mute!
                end
              end

              describe "when muted" do
                before { conference.muted! }

                it "should raise an error" do
                  lambda { conference.mute! }.should raise_error(InvalidActionError, "Cannot mute a Conference that is already muted")
                end
              end
            end

            describe "#muted!" do
              before do
                subject.request!
                subject.execute!
                subject.muted!
              end

              its(:mute_status_name) { should == :muted }

              it "should raise a StateMachine::InvalidTransition when received a second time" do
                lambda { subject.muted! }.should raise_error(StateMachine::InvalidTransition)
              end
            end

            describe '#unmute_action' do
              subject { conference.unmute_action }

              its(:to_xml) { should == '<unmute xmlns="urn:xmpp:ozone:conference:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#unmute!' do
              before do
                conference.request!
                conference.execute!
              end

              describe "when muted" do
                before do
                  conference.muted!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', conference.unmute_action, 'abc123').returns true
                  conference.expects :unmuted!
                  conference.unmute!
                end
              end

              describe "when unmuted" do
                it "should raise an error" do
                  lambda { conference.unmute! }.should raise_error(InvalidActionError, "Cannot unmute a Conference that is not muted")
                end
              end
            end

            describe "#unmuted!" do
              before do
                subject.request!
                subject.execute!
                subject.muted!
                subject.unmuted!
              end

              its(:mute_status_name) { should == :unmuted }

              it "should raise a StateMachine::InvalidTransition when received a second time" do
                lambda { subject.unmuted! }.should raise_error(StateMachine::InvalidTransition)
              end
            end

            describe '#stop_action' do
              subject { conference.stop_action }

              its(:to_xml) { should == '<stop xmlns="urn:xmpp:ozone:conference:1"/>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#stop!' do
              describe "when the command is executing" do
                before do
                  conference.request!
                  conference.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', conference.stop_action, 'abc123')
                  conference.stop!
                end
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { conference.stop! }.should raise_error(InvalidActionError, "Cannot stop a Conference that is not executing")
                end
              end
            end # describe #stop!

            describe '#kick_action' do
              subject { conference.kick_action :message => 'bye!' }

              its(:to_xml) { should == '<kick xmlns="urn:xmpp:ozone:conference:1">bye!</kick>' }
              its(:command_id) { should == 'abc123' }
              its(:call_id) { should == '123abc' }
            end

            describe '#kick!' do
              describe "when the command is executing" do
                before do
                  conference.request!
                  conference.execute!
                end

                it "should send its command properly" do
                  Connection.any_instance.expects(:write).with('123abc', conference.kick_action(:message => 'bye!'), 'abc123')
                  conference.kick! :message => 'bye!'
                end
              end

              describe "when the command is not executing" do
                it "should raise an error" do
                  lambda { conference.kick! }.should raise_error(InvalidActionError, "Cannot kick a Conference that is not executing")
                end
              end
            end # describe #kick!
          end

          describe Conference::OnHold do
            it 'registers itself' do
              OzoneNode.class_from_registration(:'on-hold', 'urn:xmpp:ozone:conference:1').should == Conference::OnHold
            end

            describe "from a stanza" do
              let(:stanza) { "<on-hold xmlns='urn:xmpp:ozone:conference:1'/>" }

              subject { OzoneNode.import parse_stanza(stanza).root, '9f00061', '1' }

              it { should be_instance_of Conference::OnHold }

              it_should_behave_like 'event'
            end
          end

          describe Conference::OffHold do
            it 'registers itself' do
              OzoneNode.class_from_registration(:'off-hold', 'urn:xmpp:ozone:conference:1').should == Conference::OffHold
            end

            describe "from a stanza" do
              let(:stanza) { "<off-hold xmlns='urn:xmpp:ozone:conference:1'/>" }

              subject { OzoneNode.import parse_stanza(stanza).root, '9f00061', '1' }

              it { should be_instance_of Conference::OffHold }

              it_should_behave_like 'event'
            end
          end

          describe Conference::Complete::Kick do
            let :stanza do
              <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <kick xmlns='urn:xmpp:ozone:conference:complete:1'>wouldn't stop talking</kick>
  </complete>
              MESSAGE
            end

            subject { OzoneNode.import(parse_stanza(stanza).root).reason }

            it { should be_instance_of Conference::Complete::Kick }

            its(:name)    { should == :kick }
            its(:details) { should == "wouldn't stop talking" }
          end

          describe Conference::Complete::Terminator do
            let :stanza do
              <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <terminator xmlns='urn:xmpp:ozone:conference:complete:1' />
  </complete>
              MESSAGE
            end

            subject { OzoneNode.import(parse_stanza(stanza).root).reason }

            it { should be_instance_of Conference::Complete::Terminator }

            its(:name) { should == :terminator }
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
