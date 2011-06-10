require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Offer do
        it 'registers itself' do
          Event.class_from_registration(:offer, 'urn:xmpp:ozone:1').should == Offer
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<offer xmlns='urn:xmpp:ozone:1'
    to='tel:+18003211212'
    from='tel:+13058881212'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="x-skill" value="agent" />
  <header name="x-customer-id" value="8877" />
</offer>
            MESSAGE
          end

          subject { Event.import parse_stanza(stanza).root, '9f00061', '1' }

          it { should be_instance_of Offer }

          it_should_behave_like 'event'
          it_should_behave_like 'event_headers'

          its(:to) { should == 'tel:+18003211212' }
          its(:from) { should == 'tel:+13058881212' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
