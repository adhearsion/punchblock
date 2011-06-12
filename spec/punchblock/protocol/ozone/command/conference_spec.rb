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
                             :beep              => true,
                             :terminator        => '#',
                             :prompt            => "Welcome to Ozone",
                             :audio_url         => "http://it.doesnt.matter.does.it/?",
                             :moderator         => true,
                             :tone_passthrough  => true,
                             :mute              => false
            end

            its(:name)              { should == '1234' }
            its(:beep)              { should == true }
            its(:mute)              { should == false }
            its(:terminator)        { should == '#' }
            its(:announcement)      { should == Conference::Announcement.new(:text => "Welcome to Ozone", :url => "http://it.doesnt.matter.does.it/?") }
            its(:tone_passthrough)  { should == true }
            its(:moderator)         { should == true }
          end

          it '"mute" message' do
            pending 'Need to construct the parent object first'
            mute.to_xml.should == '<mute xmlns="urn:xmpp:ozone:conference:1"/>'
          end

          it '"unmute" message' do
            pending 'Need to construct the parent object first'
            unmute.to_xml.should == '<unmute xmlns="urn:xmpp:ozone:conference:1"/>'
          end

          it '"kick" message' do
            pending 'Need to construct the parent object first'
            kick.to_xml.should == '<kick xmlns="urn:xmpp:ozone:conference:1"/>'
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
