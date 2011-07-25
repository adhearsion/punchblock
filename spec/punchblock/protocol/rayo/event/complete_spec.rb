require 'spec_helper'

module Punchblock
  module Protocol
    class Rayo
      module Event
        describe Complete do
          it 'registers itself' do
            RayoNode.class_from_registration(:complete, 'urn:xmpp:rayo:ext:1').should == Complete
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
    <success xmlns='urn:xmpp:rayo:say:complete:1' />
  </complete>
              MESSAGE
            end

            subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Complete }

            it_should_behave_like 'event'

            its(:reason) { should be_instance_of Command::Say::Complete::Success }
          end
        end

        describe Complete::Stop do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
    <stop xmlns='urn:xmpp:rayo:ext:complete:1' />
  </complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Stop }

          its(:name) { should == :stop }
        end

        describe Complete::Hangup do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
    <hangup xmlns='urn:xmpp:rayo:ext:complete:1' />
  </complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Hangup }

          its(:name) { should == :hangup }
        end

        describe Complete::Error do
          let :stanza do
            <<-MESSAGE
  <complete xmlns='urn:xmpp:rayo:ext:1'>
    <error xmlns='urn:xmpp:rayo:ext:complete:1'>
      Something really bad happened
    </error>
  </complete>
            MESSAGE
          end

          subject { RayoNode.import(parse_stanza(stanza).root).reason }

          it { should be_instance_of Complete::Error }

          its(:name) { should == :error }
          its(:details) { should == "Something really bad happened" }
        end
      end
    end # Rayo
  end # Protocol
end # Punchblock
