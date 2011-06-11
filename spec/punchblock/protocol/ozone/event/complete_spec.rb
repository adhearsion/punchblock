require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      module Event
        describe Complete do
          it 'registers itself' do
            OzoneNode.class_from_registration(:complete, 'urn:xmpp:ozone:ext:1').should == Complete
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <success xmlns='urn:xmpp:ozone:say:complete:1' />
  </complete>
              MESSAGE
            end

            subject { OzoneNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Complete }

            it_should_behave_like 'event'

            its(:reason) { should == Command::Say::Complete::Success.new }
          end
        end

        describe Complete::Stop do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <stop xmlns='urn:xmpp:ozone:ext:complete:1' />
  </complete>
            MESSAGE
          end

          subject { OzoneNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Stop }

          its(:name) { should == :stop }
        end

        describe Complete::Hangup do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <hangup xmlns='urn:xmpp:ozone:ext:complete:1' />
  </complete>
            MESSAGE
          end

          subject { OzoneNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Hangup }

          its(:name) { should == :hangup }
        end

        describe Complete::Error do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:ozone:ext:1'>
    <error xmlns='urn:xmpp:ozone:ext:complete:1'>
      Something really bad happened
    </error>
  </complete>
            MESSAGE
          end

          subject { OzoneNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Error }

          its(:name) { should == :error }
          its(:details) { should == "Something really bad happened" }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
