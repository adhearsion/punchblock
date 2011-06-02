require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Conference do
        subject { Conference.new '1234' }
        its(:to_xml) { should == '<conference xmlns="urn:xmpp:ozone:conference:1" name="1234"/>' }

        describe 'with options' do
          let :expected_message do
            <<-MESSAGE
<conference xmlns="urn:xmpp:ozone:conference:1" beep="true" terminator="#" moderator="true" tone-passthrough="true" mute="false" name="1234">
  <music>
    <speak>Welcome to Ozone</speak>
    <audio url="http://it.doesnt.matter.does.it/?"/>
  </music>
</conference>
            MESSAGE
          end

          subject do
            Conference.new '1234', :beep             => true,
                                   :terminator       => '#',
                                   :prompt           => "Welcome to Ozone",
                                   :audio_url        => "http://it.doesnt.matter.does.it/?",
                                   :moderator        => true,
                                   :tone_passthrough => true,
                                   :mute             => false
          end

          its(:to_xml) { should == expected_message.strip }
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
