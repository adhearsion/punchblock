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

          its(:audio) { should == Audio.new('http://whatever.you-say-boss.com') }
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
    end # Ozone
  end # Protocol
end # Punchblock
