require 'spec_helper'

module Punchblock
  module Protocol
    class Ozone
      module Event
        describe Answered do
          it 'registers itself' do
            OzoneNode.class_from_registration(:answered, 'urn:xmpp:ozone:1').should == Answered
          end

          describe "from a stanza" do
            let(:stanza) { '<answered xmlns="urn:xmpp:ozone:1"/>' }

            subject { OzoneNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Answered }

            it_should_behave_like 'event'

            its(:xmlns) { should == 'urn:xmpp:ozone:1' }
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
