require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Reject do
        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:reject, 'urn:xmpp:ozone:1').should == Reject
        end

        it 'ensures an reject node is present on create' do
          subject.find_first('/iq/ns:reject', :ns => Reject.registered_ns).should_not be_nil
        end

        it 'ensures a reject node exists when calling #reject' do
          subject.remove_children :reject
          subject.find_first('/iq/ns:reject', :ns => Reject.registered_ns).should be_nil

          subject.reject.should_not be_nil
          subject.find_first('/iq/ns:reject', :ns => Reject.registered_ns).should_not be_nil
        end

        # it 'sets the host if requested' do
        #   aff = Reject.new :get, 'reject.jabber.local'
        #   aff.to.should == Blather::JID.new('reject.jabber.local')
        # end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <reject xmlns='urn:xmpp:ozone:1'>
    <busy />
    <!-- Sample Headers (optional) -->
    <header name="x-busy-detail" value="out of licenses" />
  </reject>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Reject }

          it_should_behave_like 'message'

          its(:reject_reason) { should == :busy }
          its(:headers) { should == {:x_busy_detail => 'out of licenses'} }
        end

        # its(:to_xml) { should == expected_message.chomp }

        describe "with the reason" do
          before { pending }
          [:declined, :busy, :error].each do |reason|
            describe reason do
              subject { Reject.new reason }

              let :expected_message do
                <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <#{reason}/>
</reject>
                MESSAGE
              end

              its(:to_xml) { should == expected_message.chomp }
            end
          end

          it "blahblahblah" do
            expect { Reject.new(:blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
