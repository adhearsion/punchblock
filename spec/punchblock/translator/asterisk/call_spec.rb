# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Call do
        let(:channel)         { 'SIP/foo' }
        let(:translator)      { Asterisk.new stub('AMI Client').as_null_object, stub('connection').as_null_object }
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
            :agi_dnid         => 'unknown',
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
            :x_agi_dnid         => 'unknown',
            :x_agi_rdnis        => 'unknown',
            :x_agi_context      => 'default',
            :x_agi_extension    => '1000',
            :x_agi_priority     => '1',
            :x_agi_enhanced     => '0.0',
            :x_agi_accountcode  => '',
            :x_agi_threadid     => '4366221312'
          }
        end

        subject { Call.new channel, translator, agi_env }

        its(:id)          { should be_a String }
        its(:channel)     { should be == channel }
        its(:translator)  { should be translator }
        its(:agi_env)     { should be == agi_env }

        before { translator.stub :handle_pb_event }

        describe '#shutdown' do
          it 'should terminate the actor' do
            subject.shutdown
            sleep 0.5
            subject.should_not be_alive
          end
        end

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
            expected_offer = Punchblock::Event::Offer.new :target_call_id  => subject.id,
                                                          :to       => '1000',
                                                          :from     => 'Jane Smith <SIP/5678>',
                                                          :headers  => sip_headers
            translator.should_receive(:handle_pb_event).with expected_offer
            subject.send_offer
          end

          it 'should make the call identify as inbound' do
            subject.send_offer
            subject.direction.should be == :inbound
            subject.inbound?.should be true
            subject.outbound?.should be false
          end
        end

        describe '#send_progress' do

          context "with a call that is already answered" do
            it 'should not send the EXEC Progress command' do
              subject.wrapped_object.should_receive(:'answered?').and_return true
              subject.wrapped_object.should_receive(:send_agi_action).with("EXEC Progress").never
              subject.send_progress
            end
          end

          context "with an unanswered call" do
            before do
              subject.wrapped_object.should_receive(:'answered?').at_least(:once).and_return(false)
            end

            context "with a call that is outbound" do
              let(:dial_command) { Command::Dial.new }

              before do
                dial_command.request!
                subject.dial dial_command
              end

              it 'should not send the EXEC Progress command' do
                subject.wrapped_object.should_receive(:send_agi_action).with("EXEC Progress").never
                subject.send_progress
              end
            end

            context "with a call that is inbound" do
              before do
                subject.send_offer
              end

              it 'should send the EXEC Progress command to a call that is inbound and not answered' do
                subject.wrapped_object.should_receive(:send_agi_action).with("EXEC Progress")
                subject.send_progress
              end

              it 'should send the EXEC Progress command only once if called twice' do
                subject.wrapped_object.should_receive(:send_agi_action).with("EXEC Progress").once
                subject.send_progress
                subject.send_progress
              end
            end
          end
        end

        describe '#dial' do
          let(:dial_command_options) { {} }

          let(:to) { 'SIP/1234' }

          let :dial_command do
            Punchblock::Command::Dial.new({:to => to, :from => 'sip:foo@bar.com'}.merge(dial_command_options))
          end

          before { dial_command.request! }

          it 'sends an Originate AMI action' do
            expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
                                                                               :params => {
                                                                                 :async       => true,
                                                                                 :application => 'AGI',
                                                                                 :data        => 'agi:async',
                                                                                 :channel     => 'SIP/1234',
                                                                                 :callerid    => 'sip:foo@bar.com',
                                                                                 :variable    => "punchblock_call_id=#{subject.id}"
                                                                               }).tap { |a| a.request! }

            translator.async.should_receive(:execute_global_command).once.with expected_action
            subject.dial dial_command
          end

          context 'with a name and channel in the to field' do
            let(:to)  { 'Jane Smith <SIP/5678>' }

            it 'sends an Originate AMI action with only the channel' do
              expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
                                                                                 :params => {
                                                                                   :async       => true,
                                                                                   :application => 'AGI',
                                                                                   :data        => 'agi:async',
                                                                                   :channel     => 'SIP/5678',
                                                                                   :callerid    => 'sip:foo@bar.com',
                                                                                   :variable    => "punchblock_call_id=#{subject.id}"
                                                                                 }).tap { |a| a.request! }

              translator.async.should_receive(:execute_global_command).once.with expected_action
              subject.dial dial_command
            end
          end

          context 'with a timeout specified' do
            let :dial_command_options do
              { :timeout => 10000 }
            end

            it 'includes the timeout in the Originate AMI action' do
              expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
                                                                                 :params => {
                                                                                   :async       => true,
                                                                                   :application => 'AGI',
                                                                                   :data        => 'agi:async',
                                                                                   :channel     => 'SIP/1234',
                                                                                   :callerid    => 'sip:foo@bar.com',
                                                                                   :variable    => "punchblock_call_id=#{subject.id}",
                                                                                   :timeout     => 10000
                                                                                 }).tap { |a| a.request! }

              translator.async.should_receive(:execute_global_command).once.with expected_action
              subject.dial dial_command
            end
          end

          context 'with headers specified' do
            let :dial_command_options do
              { :headers => {'X-foo' => 'bar', 'X-doo' => 'dah'} }
            end

            it 'includes the headers in the Originate AMI action' do
              expected_action = Punchblock::Component::Asterisk::AMI::Action.new(:name => 'Originate',
                                                                                 :params => {
                                                                                   :async       => true,
                                                                                   :application => 'AGI',
                                                                                   :data        => 'agi:async',
                                                                                   :channel     => 'SIP/1234',
                                                                                   :callerid    => 'sip:foo@bar.com',
                                                                                   :variable    => "punchblock_call_id=#{subject.id},SIPADDHEADER51=\"X-foo: bar\",SIPADDHEADER52=\"X-doo: dah\""
                                                                                 }).tap { |a| a.request! }

              translator.async.should_receive(:execute_global_command).once.with expected_action
              subject.dial dial_command
            end
          end

          it 'sends the call ID as a response to the Dial' do
            subject.dial dial_command
            dial_command.response
            dial_command.target_call_id.should be == subject.id
          end

          it 'should make the call identify as outbound' do
            subject.dial dial_command
            subject.direction.should be == :outbound
            subject.outbound?.should be true
            subject.inbound?.should be false
          end

          it 'causes accepting the call to be a null operation' do
            subject.dial dial_command
            accept_command = Command::Accept.new
            accept_command.request!
            subject.wrapped_object.should_receive(:send_agi_action).never
            subject.execute_command accept_command
            accept_command.response(0.5).should be true
          end
        end

        describe '#process_ami_event' do
          context 'with a Hangup event' do
            let :ami_event do
              RubyAMI::Event.new('Hangup').tap do |e|
                e['Uniqueid']     = "1320842458.8"
                e['Calleridnum']  = "5678"
                e['Calleridname'] = "Jane Smith"
                e['Cause']        = cause
                e['Cause-txt']    = cause_txt
                e['Channel']      = "SIP/1234-00000000"
              end
            end

            let(:cause)     { '16' }
            let(:cause_txt) { 'Normal Clearing' }

            it "should cause the actor to be terminated" do
              translator.should_receive(:handle_pb_event).twice
              subject.process_ami_event ami_event
              sleep 5.5
              subject.should_not be_alive
            end

            it "de-registers the call from the translator" do
              translator.stub :handle_pb_event
              translator.should_receive(:deregister_call).once.with(subject)
              subject.process_ami_event ami_event
            end

            it "should cause all components to send complete events before sending end event" do
              comp_command = Punchblock::Component::Input.new :grammar => {:value => '<grammar/>'}, :mode => :dtmf
              comp_command.request!
              component = subject.execute_command comp_command
              comp_command.response(0.1).should be_a Ref
              expected_complete_event = Punchblock::Event::Complete.new :target_call_id => subject.id, :component_id => component.id
              expected_complete_event.reason = Punchblock::Event::Complete::Hangup.new
              expected_end_event = Punchblock::Event::End.new :reason => :hangup, :target_call_id  => subject.id

              translator.should_receive(:handle_pb_event).with(expected_complete_event).once.ordered
              translator.should_receive(:handle_pb_event).with(expected_end_event).once.ordered
              subject.process_ami_event ami_event
            end

            it "should not allow commands to be executed while components are shutting down" do
              comp_command = Punchblock::Component::Input.new :grammar => {:value => '<grammar/>'}, :mode => :dtmf
              comp_command.request!
              component = subject.execute_command comp_command
              comp_command.response(0.1).should be_a Ref

              subject.async.process_ami_event ami_event

              comp_command = Punchblock::Component::Input.new :grammar => {:value => '<grammar/>'}, :mode => :dtmf
              comp_command.request!
              subject.execute_command comp_command
              comp_command.response(0.1).should == ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id)
            end

            context "with an undefined cause" do
              let(:cause)     { '0' }
              let(:cause_txt) { 'Undefined' }

              it 'should send an end (hangup) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :hangup,
                                                                :target_call_id  => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a normal clearing cause" do
              let(:cause)     { '16' }
              let(:cause_txt) { 'Normal Clearing' }

              it 'should send an end (hangup) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :hangup,
                                                                :target_call_id  => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a user busy cause" do
              let(:cause)     { '17' }
              let(:cause_txt) { 'User Busy' }

              it 'should send an end (busy) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :busy,
                                                                :target_call_id  => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            {
              18 => 'No user response',
              102 => 'Recovery on timer expire'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (timeout) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason   => :timeout,
                                                                  :target_call_id  => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end

            {
              19 => 'No Answer',
              21 => 'Call Rejected',
              22 => 'Number Changed'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (reject) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason   => :reject,
                                                                  :target_call_id  => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end

            {
              1   => 'AST_CAUSE_UNALLOCATED',
              2   => 'NO_ROUTE_TRANSIT_NET',
              3   => 'NO_ROUTE_DESTINATION',
              6   => 'CHANNEL_UNACCEPTABLE',
              7   => 'CALL_AWARDED_DELIVERED',
              27  => 'DESTINATION_OUT_OF_ORDER',
              28  => 'INVALID_NUMBER_FORMAT',
              29  => 'FACILITY_REJECTED',
              30  => 'RESPONSE_TO_STATUS_ENQUIRY',
              31  => 'NORMAL_UNSPECIFIED',
              34  => 'NORMAL_CIRCUIT_CONGESTION',
              38  => 'NETWORK_OUT_OF_ORDER',
              41  => 'NORMAL_TEMPORARY_FAILURE',
              42  => 'SWITCH_CONGESTION',
              43  => 'ACCESS_INFO_DISCARDED',
              44  => 'REQUESTED_CHAN_UNAVAIL',
              45  => 'PRE_EMPTED',
              50  => 'FACILITY_NOT_SUBSCRIBED',
              52  => 'OUTGOING_CALL_BARRED',
              54  => 'INCOMING_CALL_BARRED',
              57  => 'BEARERCAPABILITY_NOTAUTH',
              58  => 'BEARERCAPABILITY_NOTAVAIL',
              65  => 'BEARERCAPABILITY_NOTIMPL',
              66  => 'CHAN_NOT_IMPLEMENTED',
              69  => 'FACILITY_NOT_IMPLEMENTED',
              81  => 'INVALID_CALL_REFERENCE',
              88  => 'INCOMPATIBLE_DESTINATION',
              95  => 'INVALID_MSG_UNSPECIFIED',
              96  => 'MANDATORY_IE_MISSING',
              97  => 'MESSAGE_TYPE_NONEXIST',
              98  => 'WRONG_MESSAGE',
              99  => 'IE_NONEXIST',
              100 => 'INVALID_IE_CONTENTS',
              101 => 'WRONG_CALL_STATE',
              103 => 'MANDATORY_IE_LENGTH_ERROR',
              111 => 'PROTOCOL_ERROR',
              127 => 'INTERWORKING'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (error) event to the translator' do
                  expected_end_event = Punchblock::Event::End.new :reason   => :error,
                                                                  :target_call_id  => subject.id
                  translator.should_receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end
          end

          context 'with an event for a known AGI command component' do
            let(:mock_component_node) { mock 'Punchblock::Component::Asterisk::AGI::Command', :name => 'EXEC ANSWER', :params_array => [] }
            let :component do
              Component::Asterisk::AGICommand.new mock_component_node, subject
            end

            let(:ami_event) do
              RubyAMI::Event.new("AsyncAGI").tap do |e|
                e["SubEvent"]   = "End"
                e["Channel"]    = "SIP/1234-00000000"
                e["CommandID"]  = component.id
                e["Command"]    = "EXEC ANSWER"
                e["Result"]     = "200%20result=123%20(timeout)%0A"
              end
            end

            before do
              subject.register_component component
            end

            it 'should send the event to the component' do
              component.should_receive(:handle_ami_event).once.with ami_event
              subject.process_ami_event ami_event
            end
          end

          context 'with a Newstate event' do
            let :ami_event do
              RubyAMI::Event.new('Newstate').tap do |e|
                e['Privilege']          = 'call,all'
                e['Channel']            = 'SIP/1234-00000000'
                e['ChannelState']       = channel_state
                e['ChannelStateDesc']   = channel_state_desc
                e['CallerIDNum']        = ''
                e['CallerIDName']       = ''
                e['ConnectedLineNum']   = ''
                e['ConnectedLineName']  = ''
                e['Uniqueid']           = '1326194671.0'
              end
            end

            context 'ringing' do
              let(:channel_state)       { '5' }
              let(:channel_state_desc)  { 'Ringing' }

              it 'should send a ringing event' do
                expected_ringing = Punchblock::Event::Ringing.new
                expected_ringing.target_call_id = subject.id
                translator.should_receive(:handle_pb_event).with expected_ringing
                subject.process_ami_event ami_event
              end

              it '#answered? should return false' do
                subject.process_ami_event ami_event
                subject.answered?.should be_false
              end
            end

            context 'up' do
              let(:channel_state)       { '6' }
              let(:channel_state_desc)  { 'Up' }

              it 'should send a ringing event' do
                expected_answered = Punchblock::Event::Answered.new
                expected_answered.target_call_id = subject.id
                translator.should_receive(:handle_pb_event).with expected_answered
                subject.process_ami_event ami_event
              end

              it '#answered? should be true' do
                subject.process_ami_event ami_event
                subject.answered?.should be_true
              end
            end
          end

          context 'with an OriginateResponse event' do
            let :ami_event do
              RubyAMI::Event.new('OriginateResponse').tap do |e|
                e['Privilege']    = 'call,all'
                e['ActionID']     = '9d0c1aa4-5e3b-4cae-8aef-76a6119e2909'
                e['Response']     = response
                e['Channel']      = 'SIP/15557654321'
                e['Context']      = ''
                e['Exten']        = ''
                e['Reason']       = '0'
                e['Uniqueid']     = uniqueid
                e['CallerIDNum']  = 'sip:5551234567'
                e['CallerIDName'] = 'Bryan 100'
              end
            end

            context 'sucessful' do
              let(:response)  { 'Success' }
              let(:uniqueid)  { '<null>' }

              it 'should not send an end event' do
                translator.should_receive(:handle_pb_event).once.with an_instance_of(Punchblock::Event::Asterisk::AMI::Event)
                subject.process_ami_event ami_event
              end
            end

            context 'failed after being connected' do
              let(:response)  { 'Failure' }
              let(:uniqueid)  { '1235' }

              it 'should not send an end event' do
                translator.should_receive(:handle_pb_event).once.with an_instance_of(Punchblock::Event::Asterisk::AMI::Event)
                subject.process_ami_event ami_event
              end
            end

            context 'failed without ever having connected' do
              let(:response)  { 'Failure' }
              let(:uniqueid)  { '<null>' }

              it 'should send an error end event' do
                expected_end_event = Punchblock::Event::End.new :reason         => :error,
                                                                :target_call_id => subject.id
                translator.should_receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end
          end

          context 'with a handler registered for a matching event' do
            let :ami_event do
              RubyAMI::Event.new('DTMF').tap do |e|
                e['Digit']    = '4'
                e['Start']    = 'Yes'
                e['End']      = 'No'
                e['Uniqueid'] = "1320842458.8"
                e['Channel']  = "SIP/1234-00000000"
              end
            end

            let(:response) { mock 'Response' }

            it 'should execute the handler' do
              response.should_receive(:call).once.with ami_event
              subject.register_handler :ami, :name => 'DTMF' do |event|
                response.call event
              end
              subject.process_ami_event ami_event
            end
          end

          context 'with a BridgeExec event' do
            let :ami_event do
              RubyAMI::Event.new('BridgeExec').tap do |e|
                e['Privilege'] = "call,all"
                e['Response'] = "Success"
                e['Channel1']  = "SIP/foo"
                e['Channel2']  = other_channel
              end
            end

            let(:other_channel) { 'SIP/5678-00000000' }

            context "when a join has been executed against another call" do
              let :other_call do
                Call.new other_channel, translator
              end

              let(:other_call_id) { other_call.id }
              let :command do
                Punchblock::Command::Join.new :call_id => other_call_id
              end

              before do
                translator.register_call other_call
                command.request!
                subject.execute_command command
              end

              it 'retrieves and sets success on the correct Join' do
                subject.process_ami_event ami_event
                command.response(0.5).should be == true
              end

              context "with the channel names reversed" do
                let :ami_event do
                  RubyAMI::Event.new('BridgeExec').tap do |e|
                    e['Privilege'] = "call,all"
                    e['Response'] = "Success"
                    e['Channel1']  = other_channel
                    e['Channel2']  = "SIP/foo"
                  end
                end

                it 'retrieves and sets success on the correct Join' do
                  subject.process_ami_event ami_event
                  command.response(0.5).should be == true
                end
              end
            end

            context "with no matching join command" do
              it "should do nothing" do
                expect { subject.process_ami_event ami_event }.not_to raise_error
              end
            end
          end

          context 'with a Bridge event' do
            let(:other_channel) { 'SIP/5678-00000000' }
            let(:other_call_id) { 'def567' }
            let :other_call do
              Call.new other_channel, translator
            end

            let :ami_event do
              RubyAMI::Event.new('Bridge').tap do |e|
                e['Privilege']    = "call,all"
                e['Bridgestate']  = state
                e['Bridgetype']   = "core"
                e['Channel1']     = channel
                e['Channel2']     = other_channel
                e['Uniqueid1']    = "1319717537.11"
                e['Uniqueid2']    = "1319717537.10"
                e['CallerID1']    = "1234"
                e['CallerID2']    = "5678"
              end
            end

            let :switched_ami_event do
              RubyAMI::Event.new('Bridge').tap do |e|
                e['Privilege']    = "call,all"
                e['Bridgestate']  = state
                e['Bridgetype']   = "core"
                e['Channel1']     = other_channel
                e['Channel2']     = channel
                e['Uniqueid1']    = "1319717537.11"
                e['Uniqueid2']    = "1319717537.10"
                e['CallerID1']    = "1234"
                e['CallerID2']    = "5678"
              end
            end

            before do
              translator.register_call other_call
              translator.should_receive(:call_for_channel).with(other_channel).and_return(other_call)
              other_call.should_receive(:id).and_return other_call_id
            end

            context "of state 'Link'" do
              let(:state) { 'Link' }

              let :expected_joined do
                Punchblock::Event::Joined.new.tap do |joined|
                  joined.target_call_id = subject.id
                  joined.call_id = other_call_id
                end
              end

              it 'sends the Joined event when the call is the first channel' do
                translator.should_receive(:handle_pb_event).with expected_joined
                subject.process_ami_event ami_event
              end

              it 'sends the Joined event when the call is the second channel' do
                translator.should_receive(:handle_pb_event).with expected_joined
                subject.process_ami_event switched_ami_event
              end
            end

            context "of state 'Unlink'" do
              let(:state) { 'Unlink' }

              let :expected_unjoined do
                Punchblock::Event::Unjoined.new.tap do |joined|
                  joined.target_call_id = subject.id
                  joined.call_id = other_call_id
                end
              end

              it 'sends the Unjoined event when the call is the first channel' do
                translator.should_receive(:handle_pb_event).with expected_unjoined
                subject.process_ami_event ami_event
              end

              it 'sends the Unjoined event when the call is the second channel' do
                translator.should_receive(:handle_pb_event).with expected_unjoined
                subject.process_ami_event switched_ami_event
              end
            end
          end

          context 'with an Unlink event' do
            let(:other_channel) { 'SIP/5678-00000000' }
            let(:other_call_id) { 'def567' }
            let :other_call do
              Call.new other_channel, translator
            end

            let :ami_event do
              RubyAMI::Event.new('Unlink').tap do |e|
                e['Privilege']    = "call,all"
                e['Channel1']     = channel
                e['Channel2']     = other_channel
                e['Uniqueid1']    = "1319717537.11"
                e['Uniqueid2']    = "1319717537.10"
                e['CallerID1']    = "1234"
                e['CallerID2']    = "5678"
              end
            end

            let :switched_ami_event do
              RubyAMI::Event.new('Unlink').tap do |e|
                e['Privilege']    = "call,all"
                e['Channel1']     = other_channel
                e['Channel2']     = channel
                e['Uniqueid1']    = "1319717537.11"
                e['Uniqueid2']    = "1319717537.10"
                e['CallerID1']    = "1234"
                e['CallerID2']    = "5678"
              end
            end

            before do
              translator.register_call other_call
              translator.should_receive(:call_for_channel).with(other_channel).and_return(other_call)
              other_call.should_receive(:id).and_return other_call_id
            end

            let :expected_unjoined do
              Punchblock::Event::Unjoined.new.tap do |joined|
                joined.target_call_id = subject.id
                joined.call_id = other_call_id
              end
            end

            it 'sends the Unjoined event when the call is the first channel' do
              translator.should_receive(:handle_pb_event).with expected_unjoined
              subject.process_ami_event ami_event
            end

            it 'sends the Unjoined event when the call is the second channel' do
              translator.should_receive(:handle_pb_event).with expected_unjoined
              subject.process_ami_event switched_ami_event
            end
          end

          let :ami_event do
            RubyAMI::Event.new('Foo').tap do |e|
              e['Uniqueid']     = "1320842458.8"
              e['Calleridnum']  = "5678"
              e['Calleridname'] = "Jane Smith"
              e['Cause']        = "0"
              e['Cause-txt']    = "Unknown"
              e['Channel']      = channel
            end
          end

          let :expected_pb_event do
            Event::Asterisk::AMI::Event.new :name => 'Foo',
                                            :attributes => { :channel       => channel,
                                                             :uniqueid      => "1320842458.8",
                                                             :calleridnum   => "5678",
                                                             :calleridname  => "Jane Smith",
                                                             :cause         => "0",
                                                             :'cause-txt'   => "Unknown"},
                                            :target_call_id => subject.id
          end

          it 'sends the AMI event to the connection as a PB event' do
            translator.should_receive(:handle_pb_event).with expected_pb_event
            subject.process_ami_event ami_event
          end

        end

        describe '#execute_command' do
          let :expected_agi_complete_event do
            Punchblock::Event::Complete.new.tap do |c|
              c.reason = Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code    => 200,
                                                                                              :result  => 'Success',
                                                                                              :data    => 'FOO'
            end
          end

          before do
            command.request!
          end

          context 'with an accept command' do
            let(:command) { Command::Accept.new }

            it "should send an EXEC RINGING AGI command and set the command's response" do
              component = subject.execute_command command
              component.internal.should be_true
              sleep 0.5
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC RINGING"
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end
          end

          context 'with a reject command' do
            let(:command) { Command::Reject.new }

            it "with a :busy reason should send an EXEC Busy AGI command and set the command's response" do
              command.reason = :busy
              component = subject.execute_command command
              component.internal.should be_true
              sleep 0.5
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Busy"
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end

            it "with a :decline reason should send an EXEC Busy AGI command and set the command's response" do
              command.reason = :decline
              component = subject.execute_command command
              component.internal.should be_true
              sleep 0.5
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Busy"
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end

            it "with an :error reason should send an EXEC Congestion AGI command and set the command's response" do
              command.reason = :error
              component = subject.execute_command command
              component.internal.should be_true
              sleep 0.5
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Congestion"
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end
          end

          context 'with an answer command' do
            let(:command) { Command::Answer.new }

            it "should send an ANSWER AGI command and set the command's response" do
              component = subject.execute_command command
              component.internal.should be_true
              sleep 0.5
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "ANSWER"
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end
          end

          context 'with a hangup command' do
            let(:command) { Command::Hangup.new }

            it "should send a Hangup AMI command and set the command's response" do
              translator.should_receive(:send_ami_action).once.with('Hangup', 'Channel' => channel, 'Cause' => 16).and_return RubyAMI::Response.new
              subject.execute_command command
              command.response(0.5).should be true
            end
          end

          context 'with an AGI command component' do
            let :command do
              Punchblock::Component::Asterisk::AGI::Command.new :name => 'Answer'
            end

            let(:mock_action) { Translator::Asterisk::Component::Asterisk::AGICommand.new(command, subject) }

            it 'should create an AGI command component actor and execute it asynchronously' do
              mock_action.should_receive(:internal=).never
              Component::Asterisk::AGICommand.should_receive(:new_link).once.with(command, subject).and_return mock_action
              mock_action.async.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with an Output component' do
            let :command do
              Punchblock::Component::Output.new
            end

            let(:mock_action) { Translator::Asterisk::Component::Output.new(command, subject) }

            it 'should create an Output component and execute it asynchronously' do
              Component::Output.should_receive(:new_link).once.with(command, subject).and_return mock_action
              mock_action.should_receive(:internal=).never
              mock_action.async.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with an Input component' do
            let :command do
              Punchblock::Component::Input.new
            end

            let(:mock_action) { Translator::Asterisk::Component::Input.new(command, subject) }

            it 'should create an Input component and execute it asynchronously' do
              Component::Input.should_receive(:new_link).once.with(command, subject).and_return mock_action
              mock_action.should_receive(:internal=).never
              mock_action.async.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a Record component' do
            let :command do
              Punchblock::Component::Record.new
            end

            let(:mock_action) { Translator::Asterisk::Component::Record.new(command, subject) }

            it 'should create a Record component and execute it asynchronously' do
              Component::Record.should_receive(:new_link).once.with(command, subject).and_return mock_action
              mock_action.should_receive(:internal=).never
              mock_action.async.should_receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a component command' do
            let(:component_id) { 'foobar' }

            let :command do
              Punchblock::Component::Stop.new :component_id => component_id
            end

            let :mock_component do
              mock 'Component', :id => component_id
            end

            context "for a known component ID" do
              before { subject.register_component mock_component }

              it 'should send the command to the component for execution' do
                mock_component.should_receive(:execute_command).once
                subject.execute_command command
              end
            end

            context "for a component which began executing but crashed" do
              let :component_command do
                Punchblock::Component::Asterisk::AGI::Command.new :name => 'Wait'
              end

              let(:comp_id) { component_command.response.id }

              let(:subsequent_command) { Punchblock::Component::Stop.new :component_id => comp_id }

              let :expected_event do
                Punchblock::Event::Complete.new.tap do |e|
                  e.target_call_id = subject.id
                  e.component_id = comp_id
                  e.reason = Punchblock::Event::Complete::Error.new
                end
              end

              before do
                component_command.request!
                subject.execute_command component_command
              end

              it 'sends an error in response to the command' do
                component = subject.component_with_id comp_id

                component.wrapped_object.define_singleton_method(:oops) do
                  raise 'Woops, I died'
                end

                translator.should_receive(:handle_pb_event).once.with expected_event

                lambda { component.oops }.should raise_error(/Woops, I died/)
                sleep 0.1
                component.should_not be_alive
                subject.component_with_id(comp_id).should be_nil

                subsequent_command.request!
                subject.execute_command subsequent_command
                subsequent_command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{comp_id} for call #{subject.id}", subject.id, comp_id)
              end

              context "when we dispatch the command to it" do
                it 'sends an error in response to the command' do
                  component = subject.component_with_id comp_id

                  component.should_receive(:execute_command).and_raise(Celluloid::DeadActorError)

                  subsequent_command.request!
                  subject.execute_command subsequent_command
                  subsequent_command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{comp_id} for call #{subject.id}", subject.id, comp_id)
                end
              end
            end

            context "for an unknown component ID" do
              it 'sends an error in response to the command' do
                subject.execute_command command
                command.response.should be == ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{component_id} for call #{subject.id}", subject.id, component_id)
              end
            end
          end

          context 'with a command we do not understand' do
            let :command do
              Punchblock::Command::Mute.new
            end

            it 'sends an error in response to the command' do
              subject.execute_command command
              command.response.should be == ProtocolError.new.setup('command-not-acceptable', "Did not understand command for call #{subject.id}", subject.id)
            end
          end

          context "with a join command" do
            let(:other_call_id)     { "abc123" }
            let(:other_channel)     { 'SIP/bar' }
            let(:other_translator)  { stub('Translator::Asterisk').as_null_object }

            let :other_call do
              Call.new other_channel, other_translator
            end

            let :command do
              Punchblock::Command::Join.new :call_id => other_call_id
            end

            it "executes the proper dialplan Bridge application" do
              translator.should_receive(:call_with_id).with(other_call_id).and_return(other_call)
              subject.execute_command command
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Bridge"
              agi_command.params_array.should be == [other_channel]
            end
          end

          context "with an unjoin command" do
            let(:other_call_id) { "abc123" }
            let(:other_channel) { 'SIP/bar' }

            let :other_call do
              Call.new other_channel, translator
            end

            let :command do
              Punchblock::Command::Unjoin.new :call_id => other_call_id
            end

            it "executes the unjoin through redirection" do
              translator.should_receive(:call_with_id).with(other_call_id).and_return(nil)

              translator.should_receive(:send_ami_action).once.with("Redirect",
                'Channel'   => channel,
                'Exten'     => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
                'Priority'  => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
                'Context'   => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT,
              ).and_return RubyAMI::Response.new

              subject.execute_command command

              command.response(1).should be_true
            end

            it "executes the unjoin through redirection, on the subject call and the other call" do
              translator.should_receive(:call_with_id).with(other_call_id).and_return(other_call)


              translator.should_receive(:send_ami_action).once.with("Redirect",
                'Channel'       => channel,
                'Exten'         => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
                'Priority'      => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
                'Context'       => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT,
                'ExtraChannel'  => other_channel,
                'ExtraExten'    => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
                'ExtraPriority' => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
                'ExtraContext'  => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
              ).and_return RubyAMI::Response.new

              subject.execute_command command
            end

            it "handles redirect errors" do
              translator.should_receive(:call_with_id).with(other_call_id).and_return(nil)

              error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }

              translator.should_receive(:send_ami_action).once.with("Redirect",
                'Channel'   => channel,
                'Exten'     => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
                'Priority'  => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
                'Context'   => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT,
              ).and_raise error

              subject.execute_command command
              response = command.response(1)
              response.should be_a ProtocolError
              response.text.should == 'FooBar'
            end
          end
        end#execute_command

        describe '#send_agi_action' do
          it 'should send an appropriate AsyncAGI AMI action' do
            pending
            subject.wrapped_object.should_receive(:send_ami_action).once.with('AGI', 'Command' => 'FOO', 'Channel' => subject.channel)
            subject.send_agi_action 'FOO'
          end
        end

        describe '#send_ami_action' do
          it 'should send the action to the AMI client' do
            translator.should_receive(:send_ami_action).once.with 'foo', foo: :bar
            subject.send_ami_action 'foo', foo: :bar
          end
        end

        describe '#redirect_back' do
          let(:other_channel) { 'SIP/bar' }

          let :other_call do
            Call.new other_channel, translator
          end

          it "executes the proper AMI action with only the subject call" do
            translator.should_receive(:send_ami_action).once.with 'Redirect',
              'Exten'     => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
              'Priority'  => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
              'Context'   => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT,
              'Channel'   => channel
            subject.redirect_back
          end

          it "executes the proper AMI action with another call specified" do
            translator.should_receive(:send_ami_action).once.with 'Redirect',
              'Channel'       => channel,
              'Exten'         => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
              'Priority'      => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
              'Context'       => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT,
              'ExtraChannel'  => other_channel,
              'ExtraExten'    => Punchblock::Translator::Asterisk::REDIRECT_EXTENSION,
              'ExtraPriority' => Punchblock::Translator::Asterisk::REDIRECT_PRIORITY,
              'ExtraContext'  => Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
            subject.redirect_back other_call
          end
        end
      end
    end
  end
end
