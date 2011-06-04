require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Conference do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:conference, 'urn:xmpp:ozone:conference:1').should == Conference
        end

        it 'ensures an conference node is present on create' do
          subject.find_first('/iq/ns:conference', :ns => Conference.registered_ns).should_not be_nil
        end

        it 'ensures a conference node exists when calling #conference' do
          subject.remove_children :conference
          subject.find_first('/iq/ns:conference', :ns => Conference.registered_ns).should be_nil

          subject.conference.should_not be_nil
          subject.find_first('/iq/ns:conference', :ns => Conference.registered_ns).should_not be_nil
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

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <conference xmlns='urn:xmpp:ozone:conference:1'
      name='1234'
      mute='false'
      terminator='*'
      tone-passthrough='true'
      moderator='true'>
    <announcement voice="allison">
      Jose de Castro has entered the conference
    </announcement>
    <music voice="herbert">
      The moderator how not yet joined.. Listen to this awesome music while you wait.
      <audio url='http://www.yanni.com/music/awesome.mp3' />
    </music>
  </conference>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Conference }

          it_should_behave_like 'message'

          its(:name)              { should == '1234' }
          its(:mute)              { should == false }
          its(:terminator)        { should == '*' }
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
