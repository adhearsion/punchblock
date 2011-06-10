require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Say do
        it 'registers itself' do
          Command.class_from_registration(:say, 'urn:xmpp:ozone:say:1').should == Say
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

        it '"pause" message' do
          pending 'Need to construct the parent object first'
          pause.to_xml.should == '<pause xmlns="urn:xmpp:ozone:say:1"/>'
        end

        it '"resume" message' do
          pending 'Need to construct the parent object first'
          resume(:say).to_xml.should == '<resume xmlns="urn:xmpp:ozone:say:1"/>'
        end

        it '"stop" message' do
          pending 'Need to construct the parent object first'
          stop(:say).to_xml.should == '<stop xmlns="urn:xmpp:ozone:say:1"/>'
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

        subject { Event.import(parse_stanza(stanza).root).reason }

        it { should be_instance_of Say::Complete::Success }

        its(:name) { should == :success }
      end
    end # Ozone
  end # Protocol
end # Punchblock
