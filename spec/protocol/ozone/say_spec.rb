require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Say do
        describe "for audio" do
          subject { Say.new :url => 'http://whatever.you-say-boss.com' }

          let :expected_message do
            <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1">
  <audio src="http://whatever.you-say-boss.com"/>
</say>
            MESSAGE
          end

          its(:to_xml) { should == expected_message.strip }
        end

        describe "for text" do
          subject { Say.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

          let :expected_message do
            '<say xmlns="urn:xmpp:ozone:say:1" voice="kate">Once upon a time there was a message...</say>'
          end

          its(:to_xml) { should == expected_message.strip }
        end

        describe "for SSML" do
          subject { Say.new :ssml => '<say-as interpret-as="ordinal">100</say-as>', :voice => 'kate' }

          let :expected_message do
            <<-MESSAGE
<say xmlns="urn:xmpp:ozone:say:1" voice="kate">
  <say-as interpret-as="ordinal">100</say-as>
</say>
            MESSAGE
          end

          its(:to_xml) { should == expected_message.strip }
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
    end
  end
end
