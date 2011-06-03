require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Ask do
        # subject { Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]' }

        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:ask, 'urn:xmpp:ozone:ask:1').should == Ask
        end

        it 'ensures an ask node is present on create' do
          subject.find_first('/iq/ns:ask', :ns => Ask.registered_ns).should_not be_nil
        end

        it 'ensures a ask node exists when calling #ask' do
          subject.remove_children :ask
          subject.find_first('/iq/ns:ask', :ns => Ask.registered_ns).should be_nil

          subject.ask.should_not be_nil
          subject.find_first('/iq/ns:ask', :ns => Ask.registered_ns).should_not be_nil
        end

        # it 'sets the host if requested' do
        #   aff = Ask.new :get, 'ask.jabber.local'
        #   aff.to.should == Blather::JID.new('ask.jabber.local')
        # end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <ask xmlns='urn:xmpp:ozone:ask:1'
      bargein='true'
      min-confidence='0.3'
      mode='speech'
      recognizer='en-US'
      terminator='#'
      timeout='12000'>
    <prompt voice='allison'>
      Please enter your four digit pin
    </prompt>
    <choices content-type='application/grammar+voxeo'>
      [4 DIGITS]
    </choices>
  </ask>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Ask }

          it_should_behave_like 'message'

          its(:bargein)           { should == true }
          its(:min_confidence)    { should == 0.3 }
          its(:mode)              { should == :speech }
          its(:recognizer)        { should == 'en-US' }
          its(:terminator)        { should == '#' }
          its(:response_timeout)  { should == 12000 }
          its(:choices)           { should == {:content_type => 'application/grammar+voxeo', :value => '[4 DIGITS]'} }
        end

#         let :expected_message do
#           <<-MESSAGE
# <ask xmlns="urn:xmpp:ozone:ask:1">
#   <prompt>Please enter your postal code.</prompt>
#   <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
# </ask>
#           MESSAGE
#         end
#
#         its(:to_xml) { should == expected_message.strip }
#
#         describe "with an alternate grammar" do
#           subject { Ask.new 'Please enter your postal code.', :choices => '[5 DIGITS]', :grammar => 'application/grammar+custom' }
#
#           let :expected_message do
#             <<-MESSAGE
# <ask xmlns="urn:xmpp:ozone:ask:1">
#   <prompt>Please enter your postal code.</prompt>
#   <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
# </ask>
#             MESSAGE
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
#
#         describe 'with a GRXML grammar' do
#           subject { Ask.new 'Please enter your postal code.', :choices => grxml, :grammar => 'application/grammar+grxml' }
#
#           let :grxml do
#             <<-GRXML
# <grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE">
#     <rule id="MAINRULE">
#         <one-of>
#             <item>
#                 <item repeat="0-1"> need a</item>
#                 <item repeat="0-1"> i need a</item>
#                     <one-of>
#                         <item> clue </item>
#                     </one-of>
#                 <tag> out.concept = "clue";</tag>
#             </item>
#             <item>
#                 <item repeat="0-1"> have an</item>
#                 <item repeat="0-1"> i have an</item>
#                     <one-of>
#                         <item> answer </item>
#                     </one-of>
#                 <tag> out.concept = "answer";</tag>
#             </item>
#             </one-of>
#     </rule>
# </grammar>
#             GRXML
#           end
#
#           let :expected_message do
#             <<-MESSAGE
# <ask xmlns="urn:xmpp:ozone:ask:1">
#   <prompt>Please enter your postal code.</prompt>
#   <choices content-type="application/grammar+grxml"><![CDATA[<grammar xmlns="http://www.w3.org/2001/06/grammar" root="MAINRULE">
#     <rule id="MAINRULE">
#         <one-of>
#             <item>
#                 <item repeat="0-1"> need a</item>
#                 <item repeat="0-1"> i need a</item>
#                     <one-of>
#                         <item> clue </item>
#                     </one-of>
#                 <tag> out.concept = "clue";</tag>
#             </item>
#             <item>
#                 <item repeat="0-1"> have an</item>
#                 <item repeat="0-1"> i have an</item>
#                     <one-of>
#                         <item> answer </item>
#                     </one-of>
#                 <tag> out.concept = "answer";</tag>
#             </item>
#             </one-of>
#     </rule>
# </grammar>
# ]]></choices>
# </ask>
#             MESSAGE
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
#
#         describe 'with alternate grammar, voice and attributes' do
#           subject do
#             Ask.new 'Please enter your postal code.', :choices        => '[5 DIGITS]',
#                                                       :grammar        => 'application/grammar+custom',
#                                                       :voice          => 'kate',
#                                                       :bargein        => true,
#                                                       :min_confidence => '0.3',
#                                                       :mode           => :speech,
#                                                       :recognizer     => 'en-US',
#                                                       :terminator     => '#',
#                                                       :timeout        => 12000
#           end
#
#           let :expected_message do
#             <<-MESSAGE
# <ask xmlns="urn:xmpp:ozone:ask:1" bargein="true" min-confidence="0.3" mode="speech" recognizer="en-US" terminator="#" timeout="12000">
#   <prompt voice="kate">Please enter your postal code.</prompt>
#   <choices content-type="application/grammar+custom">[5 DIGITS]</choices>
# </ask>
#             MESSAGE
#           end
#
#           its(:to_xml) { should == expected_message.strip }
#         end
      end
    end # Ozone
  end # Protocol
end # Punchblock
