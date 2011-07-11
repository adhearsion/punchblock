require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Event
        describe DTMF do
          it 'registers itself' do
            OzoneNode.class_from_registration(:dtmf, 'urn:xmpp:ozone:1').should == DTMF
          end

          describe "from a stanza" do
            let(:stanza) { "<dtmf xmlns='urn:xmpp:ozone:1' signal='#' />" }

            subject { OzoneNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of DTMF }

            it_should_behave_like 'event'

            its(:signal) { should == '#' }
            its(:xmlns) { should == 'urn:xmpp:ozone:1' }
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
