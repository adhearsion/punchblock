require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Transfer do
        it 'registers itself' do
          Command.class_from_registration(:transfer, 'urn:xmpp:ozone:transfer:1').should == Transfer
        end

        describe 'when setting options in initializer' do
          subject do
            Transfer.new 'tel:+14045551212', :from            => 'tel:+14155551212',
                                             :terminator      => '*',
                                             :timeout         => 120000,
                                             :answer_on_media => true
          end

          its(:to) { should == %w{tel:+14045551212} }
          its(:from) { should == 'tel:+14155551212' }
          its(:terminator) { should == '*' }
          its(:timeout) { should == 120000 }
          its(:answer_on_media) { should == true }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
