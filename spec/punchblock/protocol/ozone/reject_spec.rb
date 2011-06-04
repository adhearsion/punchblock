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

        describe "when setting options in initializer" do
          subject { Reject.new :busy, :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

          its(:reject_reason) { should == :busy }
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <reject xmlns='urn:xmpp:ozone:1'>
    <busy />
    <!-- Sample Headers (optional) -->
    <header name="x-skill" value="agent" />
    <header name="x-customer-id" value="8877" />
  </reject>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Reject }

          def num_arguments_pre_options
            1
          end

          it_should_behave_like 'message'
          it_should_behave_like 'headers'

          its(:reject_reason) { should == :busy }
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
