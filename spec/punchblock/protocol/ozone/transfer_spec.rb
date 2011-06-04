require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Transfer do

        it 'registers itself' do
          Blather::XMPPNode.class_from_registration(:transfer, 'urn:xmpp:ozone:transfer:1').should == Transfer
        end

        it 'ensures an transfer node is present on create' do
          subject.find_first('/iq/ns:transfer', :ns => Transfer.registered_ns).should_not be_nil
        end

        it 'ensures a transfer node exists when calling #transfer' do
          subject.remove_children :transfer
          subject.find_first('/iq/ns:transfer', :ns => Transfer.registered_ns).should be_nil

          subject.transfer.should_not be_nil
          subject.find_first('/iq/ns:transfer', :ns => Transfer.registered_ns).should_not be_nil
        end

        describe 'when setting options in initializer' do
          subject do
            Transfer.new 'tel:+14045551212', :from            => 'tel:+14155551212',
                                             :terminator      => '*',
                                             :timeout         => 120000,
                                             :answer_on_media => true
          end

          its(:transfer_to) { should == %w{tel:+14045551212} }
          its(:transfer_from) { should == 'tel:+14155551212' }
          its(:terminator) { should == '*' }
          its(:timeout) { should == 120000 }
          its(:answer_on_media) { should == true }
        end

        describe "from a stanza" do
          let :stanza do
            <<-MESSAGE
<iq type='set' to='9f00061@call.ozone.net/1' from='16577@app.ozone.net/1'>
  <transfer xmlns='urn:xmpp:ozone:transfer:1'
      from='tel:+14152226789'
      terminator='*'
      timeout='120000'
      answer-on-media='true'>
    <to>tel:+4159996565</to>
    <to>tel:+3059871234</to>
    <ring voice='allison'>
      <audio url='http://acme.com/transfering.mp3'>
          Please wait while your call is being transfered.
      </audio>
    </ring>
  </transfer>
</iq>
            MESSAGE
          end

          subject { Blather::XMPPNode.import parse_stanza(stanza).root }

          it { should be_instance_of Transfer }

          it_should_behave_like 'message'

          its(:transfer_to) { should == %w{tel:+4159996565 tel:+3059871234} }
          its(:transfer_from) { should == 'tel:+14152226789' }
          its(:terminator) { should == '*' }
          its(:timeout) { should == 120000 }
          its(:answer_on_media) { should == true }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
