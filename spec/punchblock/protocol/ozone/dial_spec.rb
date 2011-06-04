require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Dial do

        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:dial, 'urn:xmpp:ozone:1').should == Dial
        end

        it 'ensures an dial node is present on create' do
          subject.find_first('/iq/ns:dial', :ns => Dial.registered_ns).should_not be_nil
        end

        it 'ensures a dial node exists when calling #dial' do
          subject.remove_children :dial
          subject.find_first('/iq/ns:dial', :ns => Dial.registered_ns).should be_nil

          subject.dial.should_not be_nil
          subject.find_first('/iq/ns:dial', :ns => Dial.registered_ns).should_not be_nil
        end

        describe "when setting options in initializer" do
          subject { Dial.new 'tel:+14155551212', 'tel:+13035551212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

          its(:dial_to) { should == 'tel:+14155551212' }
          its(:dial_from) { should == 'tel:+13035551212' }
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='call.ozone.net' from='16577@app.ozone.net/1'>
   <dial to='tel:+13055195825' from='tel:+14152226789' xmlns='urn:xmpp:ozone:1'>
      <header name="x-skill" value="agent" />
      <header name="x-customer-id" value="8877" />
   </dial>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Dial }

          def num_arguments_pre_options
            2
          end

          it_should_behave_like 'headers'

          its(:dial_to) { should == 'tel:+13055195825' }
          its(:dial_from) { should == 'tel:+14152226789' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
