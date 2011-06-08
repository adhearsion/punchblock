require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Conference do
        it 'registers itself' do
          Command.class_from_registration(:conference, 'urn:xmpp:ozone:conference:1').should == Conference
        end

        describe "when setting options in initializer" do
          subject do
            Conference.new '1234', :beep             => true,
                                   :terminator       => '#',
                                   :prompt           => "Welcome to Ozone",
                                   :audio_url        => "http://it.doesnt.matter.does.it/?",
                                   :moderator        => true,
                                   :tone_passthrough => true,
                                   :mute             => false
          end

          its(:name)              { should == '1234' }
          its(:beep)              { should == true }
          its(:mute)              { should == false }
          its(:terminator)        { should == '#' }
          its(:prompt)            { should == "Welcome to Ozone" }
          its(:audio_url)         { pending; should == "http://it.doesnt.matter.does.it/?" }
          its(:tone_passthrough)  { should == true }
          its(:moderator)         { should == true }
          its(:announcement)      { should == {:voice => 'allison', :text => 'Jose de Castro has entered the conference'} }
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
      end
    end # Ozone
  end # Protocol
end # Punchblock
