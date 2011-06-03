require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Say do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:say, 'urn:xmpp:ozone:say:1').should == Say
        end

        it 'ensures an say node is present on create' do
          subject.find_first('/iq/ns:say', :ns => Say.registered_ns).should_not be_nil
        end

        it 'ensures a say node exists when calling #say' do
          subject.remove_children :say
          subject.find_first('/iq/ns:say', :ns => Say.registered_ns).should be_nil

          subject.say.should_not be_nil
          subject.find_first('/iq/ns:say', :ns => Say.registered_ns).should_not be_nil
        end

        # it 'sets the host if requested' do
        #   aff = Say.new :get, 'say.jabber.local'
        #   aff.to.should == Blather::JID.new('say.jabber.local')
        # end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <say xmlns='urn:xmpp:ozone:say:1'
      voice='allison'>
    <audio url='http://acme.com/greeting.mp3'>
        Thanks for calling ACME company
    </audio>
    <audio url='http://acme.com/package-shipped.mp3'>
        Your package was shipped on
    </audio>
    <say-as interpret-as='date'>12/01/2011</say-as>
  </say>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Say }

          it_should_behave_like 'message'

          its(:voice) { should == 'allison' }
        end

#         describe "for audio" do
#           subject { Say.new :url => 'http://whatever.you-say-boss.com' }
#
#           let :expected_message do
#             <<-MESSAGE
# <say xmlns="urn:xmpp:ozone:say:1">
#   <audio src="http://whatever.you-say-boss.com"/>
# </say>
#             MESSAGE
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
#
#         describe "for text" do
#           subject { Say.new :text => 'Once upon a time there was a message...', :voice => 'kate' }
#
#           let :expected_message do
#             '<say xmlns="urn:xmpp:ozone:say:1" voice="kate">Once upon a time there was a message...</say>'
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
#
#         describe "for SSML" do
#           subject { Say.new :ssml => '<say-as interpret-as="ordinal">100</say-as>', :voice => 'kate' }
#
#           let :expected_message do
#             <<-MESSAGE
# <say xmlns="urn:xmpp:ozone:say:1" voice="kate">
#   <say-as interpret-as="ordinal">100</say-as>
# </say>
#             MESSAGE
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
#
#         it '"pause" message' do
#           pending 'Need to construct the parent object first'
#           pause.to_xml.should == '<pause xmlns="urn:xmpp:ozone:say:1"/>'
#         end
#
#         it '"resume" message' do
#           pending 'Need to construct the parent object first'
#           resume(:say).to_xml.should == '<resume xmlns="urn:xmpp:ozone:say:1"/>'
#         end
#
#         it '"stop" message' do
#           pending 'Need to construct the parent object first'
#           stop(:say).to_xml.should == '<stop xmlns="urn:xmpp:ozone:say:1"/>'
#         end
      end
    end # Ozone
  end # Protocol
end # Punchblock
