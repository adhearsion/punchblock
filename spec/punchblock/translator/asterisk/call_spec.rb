require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Call do
        let(:channel)     { 'SIP/foo' }
        let(:translator)  { stub_everything 'Translator::Asterisk' }
        let(:env)         { "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A" }
        let(:agi_env) do
          {
            :agi_request      => 'async',
            :agi_channel      => 'SIP/1234-00000000',
            :agi_language     => 'en',
            :agi_type         => 'SIP',
            :agi_uniqueid     => '1320835995.0',
            :agi_version      => '1.8.4.1',
            :agi_callerid     => '5678',
            :agi_calleridname => 'Jane Smith',
            :agi_callingpres  => '0',
            :agi_callingani2  => '0',
            :agi_callington   => '0',
            :agi_callingtns   => '0',
            :agi_dnid         => '1000',
            :agi_rdnis        => 'unknown',
            :agi_context      => 'default',
            :agi_extension    => '1000',
            :agi_priority     => '1',
            :agi_enhanced     => '0.0',
            :agi_accountcode  => '',
            :agi_threadid     => '4366221312'
          }
        end

        let :sip_headers do
          {
            :x_agi_request      => 'async',
            :x_agi_channel      => 'SIP/1234-00000000',
            :x_agi_language     => 'en',
            :x_agi_type         => 'SIP',
            :x_agi_uniqueid     => '1320835995.0',
            :x_agi_version      => '1.8.4.1',
            :x_agi_callerid     => '5678',
            :x_agi_calleridname => 'Jane Smith',
            :x_agi_callingpres  => '0',
            :x_agi_callingani2  => '0',
            :x_agi_callington   => '0',
            :x_agi_callingtns   => '0',
            :x_agi_dnid         => '1000',
            :x_agi_rdnis        => 'unknown',
            :x_agi_context      => 'default',
            :x_agi_extension    => '1000',
            :x_agi_priority     => '1',
            :x_agi_enhanced     => '0.0',
            :x_agi_accountcode  => '',
            :x_agi_threadid     => '4366221312'
          }
        end

        subject { Call.new channel, translator, env }

        its(:id)          { should be_a String }
        its(:channel)     { should == channel }
        its(:translator)  { should be translator }
        its(:agi_env)     { should == agi_env }

        describe '#register_component' do
          it 'should make the component accessible by ID' do
            component_id = 'abc123'
            component    = mock 'Translator::Asterisk::Component', :id => component_id
            subject.register_component component
            subject.component_with_id(component_id).should be component
          end
        end

        describe '#send_offer' do
          it 'sends an offer to the translator' do
            expected_offer = Punchblock::Event::Offer.new :call_id  => subject.id,
                                                          :to       => '1000',
                                                          :from     => 'sip:5678',
                                                          :headers  => sip_headers
            translator.expects(:handle_pb_event!).with expected_offer
            subject.send_offer
          end
        end
      end
    end
  end
end
