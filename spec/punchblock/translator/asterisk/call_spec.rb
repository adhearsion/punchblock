# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Call do
        let(:channel)         { 'SIP/foo' }
        let(:translator)      { stub_everything 'Translator::Asterisk' }
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
                                                          :from     => 'Jane Smith <sip:5678>',
                                                          :headers  => sip_headers
            translator.expects(:handle_pb_event!).with expected_offer
            subject.send_offer
          end

          it 'should make the call identify as inbound' do
            subject.send_offer
            subject.direction.should be == :inbound
            subject.inbound?.should be true
            subject.outbound?.should be false
          end
        end

        describe '#answer_if_not_answered' do
          let(:answer_command) { Command::Answer.new.tap { |a| a.request! } }

          context "with a call that is already answered" do
            it 'should not answer the call' do
              subject.wrapped_object.expects(:'answered?').returns true
              subject.wrapped_object.expects(:execute_command).never
              subject.answer_if_not_answered
            end
          end

          context "with an unanswered call" do
            before do
              subject.wrapped_object.expects(:'answered?').returns false
            end

            context "with a call that is outbound" do
              let(:dial_command) { Command::Dial.new }

              before do
                dial_command.request!
                subject.dial dial_command
              end

              it 'should not answer the call' do
                subject.wrapped_object.expects(:execute_command).never
                subject.answer_if_not_answered
              end
            end

            context "with a call that is inbound" do
              before do
                subject.send_offer
              end

              it 'should answer a call that is inbound and not answered' do
                subject.wrapped_object.expects(:execute_command).with(answer_command)
                subject.answer_if_not_answered
              end
            end
          end
        end

        describe '#dial' do
          let(:dial_command_options) { {} }

          let :dial_command do
            Punchblock::Command::Dial.new({:to => 'SIP/1234', :from => 'sip:foo@bar.com'}.merge(dial_command_options))
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

            translator.expects(:execute_global_command!).once.with expected_action
            subject.dial dial_command
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

              translator.expects(:execute_global_command!).once.with expected_action
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
            subject.wrapped_object.expects(:send_agi_action).never
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
              translator.expects(:handle_pb_event!).once
              subject.process_ami_event ami_event
              sleep 5.5
              subject.should_not be_alive
            end

            it "should cause all components to send complete events before sending end event", :focus => true do
              subject.expects :answer_if_not_answered
              comp_command = Punchblock::Component::Input.new :grammar => {:value => '<grammar/>'}, :mode => :dtmf
              comp_command.request!
              component = subject.execute_command comp_command
              comp_command.response(0.1).should be_a Ref
              expected_complete_event = Punchblock::Event::Complete.new :target_call_id => subject.id, :component_id => component.id
              expected_complete_event.reason = Punchblock::Event::Complete::Hangup.new
              expected_end_event = Punchblock::Event::End.new :reason => :hangup, :target_call_id  => subject.id
              end_sequence = sequence 'end events'
              translator.expects(:handle_pb_event!).with(expected_complete_event).once.in_sequence(end_sequence)
              translator.expects(:handle_pb_event!).with(expected_end_event).once.in_sequence(end_sequence)
              subject.process_ami_event ami_event
            end

            context "with an undefined cause" do
              let(:cause)     { '0' }
              let(:cause_txt) { 'Undefined' }

              it 'should send an end (hangup) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :hangup,
                                                                :target_call_id  => subject.id
                translator.expects(:handle_pb_event!).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a normal clearing cause" do
              let(:cause)     { '16' }
              let(:cause_txt) { 'Normal Clearing' }

              it 'should send an end (hangup) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :hangup,
                                                                :target_call_id  => subject.id
                translator.expects(:handle_pb_event!).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a user busy cause" do
              let(:cause)     { '17' }
              let(:cause_txt) { 'User Busy' }

              it 'should send an end (busy) event to the translator' do
                expected_end_event = Punchblock::Event::End.new :reason   => :busy,
                                                                :target_call_id  => subject.id
                translator.expects(:handle_pb_event!).with expected_end_event
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
                  translator.expects(:handle_pb_event!).with expected_end_event
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
                  translator.expects(:handle_pb_event!).with expected_end_event
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
                  translator.expects(:handle_pb_event!).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end
          end

          context 'with an event for a known AGI command component' do
            let(:mock_component_node) { mock 'Punchblock::Component::Asterisk::AGI::Command', :name => 'EXEC ANSWER', :params_array => [] }
            let :component do
              Component::Asterisk::AGICommand.new mock_component_node, subject.translator
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
              component.expects(:handle_ami_event!).once.with ami_event
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
                translator.expects(:handle_pb_event!).with expected_ringing
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
                translator.expects(:handle_pb_event!).with expected_answered
                subject.process_ami_event ami_event
              end

              it '#answered? should be true' do
                subject.process_ami_event ami_event
                subject.answered?.should be_true
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
              response.expects(:call).once.with ami_event
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
                e['Channel2']  = "SIP/5678-00000000"
              end
            end

            let(:other_channel) { 'SIP/5678-00000000' }
            let(:other_call_id) { 'def567' }
            let :command do
              Punchblock::Command::Join.new :call_id => other_call_id
            end

            before do
              subject.pending_joins[other_channel] = command
              command.request!
            end

            it 'retrieves and sets success on the correct Join' do
              subject.process_ami_event ami_event
              command.response(0.5).should be == true
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
              translator.expects(:call_for_channel).with(other_channel).returns(other_call)
              other_call.expects(:id).returns other_call_id
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
                translator.expects(:handle_pb_event!).with expected_joined
                subject.process_ami_event ami_event
              end

              it 'sends the Joined event when the call is the second channel' do
                translator.expects(:handle_pb_event!).with expected_joined
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
                translator.expects(:handle_pb_event!).with expected_unjoined
                subject.process_ami_event ami_event
              end

              it 'sends the Unjoined event when the call is the second channel' do
                translator.expects(:handle_pb_event!).with expected_unjoined
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
              translator.expects(:call_for_channel).with(other_channel).returns(other_call)
              other_call.expects(:id).returns other_call_id
            end

            let :expected_unjoined do
              Punchblock::Event::Unjoined.new.tap do |joined|
                joined.target_call_id = subject.id
                joined.call_id = other_call_id
              end
            end

            it 'sends the Unjoined event when the call is the first channel' do
              translator.expects(:handle_pb_event!).with expected_unjoined
              subject.process_ami_event ami_event
            end

            it 'sends the Unjoined event when the call is the second channel' do
              translator.expects(:handle_pb_event!).with expected_unjoined
              subject.process_ami_event switched_ami_event
            end
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
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC RINGING"
              agi_command.execute!
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
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Busy"
              agi_command.execute!
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end

            it "with a :decline reason should send an EXEC Busy AGI command and set the command's response" do
              command.reason = :decline
              component = subject.execute_command command
              component.internal.should be_true
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Busy"
              agi_command.execute!
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end

            it "with an :error reason should send an EXEC Congestion AGI command and set the command's response" do
              command.reason = :error
              component = subject.execute_command command
              component.internal.should be_true
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Congestion"
              agi_command.execute!
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end
          end

          context 'with an answer command' do
            let(:command) { Command::Answer.new }

            it "should send an EXEC ANSWER AGI command and set the command's response" do
              component = subject.execute_command command
              component.internal.should be_true
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC ANSWER"
              agi_command.execute!
              agi_command.add_event expected_agi_complete_event
              command.response(0.5).should be true
            end
          end

          context 'with a hangup command' do
            let(:command) { Command::Hangup.new }

            it "should send a Hangup AMI command and set the command's response" do
              subject.execute_command command
              ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
              ami_action.name.should be == "hangup"
              ami_action << RubyAMI::Response.new
              command.response(0.5).should be true
            end
          end

          context 'with an AGI command component' do
            let :command do
              Punchblock::Component::Asterisk::AGI::Command.new :name => 'Answer'
            end

            let(:mock_action) { mock 'Component::Asterisk::AGI::Command', :id => 'foo' }

            it 'should create an AGI command component actor and execute it asynchronously' do
              mock_action.expects(:internal=).never
              Component::Asterisk::AGICommand.expects(:new).once.with(command, subject).returns mock_action
              mock_action.expects(:execute!).once
              subject.execute_command command
            end
          end

          context 'with an Output component' do
            let :command do
              Punchblock::Component::Output.new
            end

            let(:mock_action) { mock 'Component::Asterisk::Output', :id => 'foo' }

            it 'should create an Output component and execute it asynchronously' do
              Component::Output.expects(:new).once.with(command, subject).returns mock_action
              mock_action.expects(:internal=).never
              mock_action.expects(:execute!).once
              subject.execute_command command
            end
          end

          context 'with an Input component' do
            let :command do
              Punchblock::Component::Input.new
            end

            let(:mock_action) { mock 'Component::Asterisk::Input', :id => 'foo' }

            it 'should create an Input component and execute it asynchronously' do
              Component::Input.expects(:new).once.with(command, subject).returns mock_action
              mock_action.expects(:internal=).never
              mock_action.expects(:execute!).once
              subject.execute_command command
            end
          end

          context 'with a Record component' do
            let :command do
              Punchblock::Component::Record.new
            end

            let(:mock_action) { mock 'Component::Asterisk::Record', :id => 'foo' }

            it 'should create a Record component and execute it asynchronously' do
              Component::Record.expects(:new).once.with(command, subject).returns mock_action
              mock_action.expects(:internal=).never
              mock_action.expects(:execute!).once
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
                mock_component.expects(:execute_command!).once
                subject.execute_command command
              end
            end

            context "for an unknown component ID" do
              it 'sends an error in response to the command' do
                subject.execute_command command
                command.response.should be == ProtocolError.new.setup('component-not-found', "Could not find a component with ID #{component_id} for call #{subject.id}", subject.id, component_id)
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
            let(:other_translator)  { stub_everything 'Translator::Asterisk' }

            let :other_call do
              Call.new other_channel, other_translator
            end

            let :command do
              Punchblock::Command::Join.new :call_id => other_call_id
            end

            it "executes the proper dialplan Bridge application" do
              translator.expects(:call_with_id).with(other_call_id).returns(other_call)
              subject.execute_command command
              agi_command = subject.wrapped_object.instance_variable_get(:'@current_agi_command')
              agi_command.name.should be == "EXEC Bridge"
              agi_command.params_array.should be == [other_channel]
            end

            it "adds the join to the @pending_joins hash" do
              translator.expects(:call_with_id).with(other_call_id).returns(other_call)
              subject.execute_command command
              subject.pending_joins[other_channel].should be command
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
              translator.expects(:call_with_id).with(other_call_id).returns(nil)
              subject.execute_command command
              ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
              ami_action.name.should be == "redirect"
              ami_action.headers['Channel'].should be == channel
              ami_action.headers['Exten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['Priority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['Context'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
            end

            it "executes the unjoin through redirection, on the subject call and the other call" do
              translator.expects(:call_with_id).with(other_call_id).returns(other_call)
              subject.execute_command command
              ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
              ami_action.name.should be == "redirect"
              ami_action.headers['Channel'].should be == channel
              ami_action.headers['Exten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['Priority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['Context'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT

              ami_action.headers['ExtraChannel'].should be == other_channel
              ami_action.headers['ExtraExten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['ExtraPriority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['ExtraContext'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
            end
          end
        end#execute_command

        describe '#send_agi_action' do
          it 'should send an appropriate AsyncAGI AMI action' do
            pending
            subject.wrapped_object.expects(:send_ami_action).once.with('AGI', 'Command' => 'FOO', 'Channel' => subject.channel)
            subject.send_agi_action 'FOO'
          end
        end

        describe '#send_ami_action' do
          let(:component_id) { UUIDTools::UUID.random_create }
          before { UUIDTools::UUID.stubs :random_create => component_id }

          it 'should send the action to the AMI client' do
            action = RubyAMI::Action.new 'foo', :foo => :bar
            translator.expects(:send_ami_action!).once.with action
            subject.send_ami_action 'foo', :foo => :bar
          end
        end

        describe '#redirect_back' do
            let(:other_channel)         { 'SIP/bar' }
            let :other_call do
              Call.new other_channel, translator
            end

            it "executes the proper AMI action with only the subject call" do
              subject.redirect_back
              ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
              ami_action.name.should be == "redirect"
              ami_action.headers['Channel'].should be == channel
              ami_action.headers['Exten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['Priority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['Context'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
            end

            it "executes the proper AMI action with another call specified" do
              subject.redirect_back other_call
              ami_action = subject.wrapped_object.instance_variable_get(:'@current_ami_action')
              ami_action.name.should be == "redirect"
              ami_action.headers['Channel'].should be == channel
              ami_action.headers['Exten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['Priority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['Context'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
              ami_action.headers['ExtraChannel'].should be == other_channel
              ami_action.headers['ExtraExten'].should be == Punchblock::Translator::Asterisk::REDIRECT_EXTENSION
              ami_action.headers['ExtraPriority'].should be == Punchblock::Translator::Asterisk::REDIRECT_PRIORITY
              ami_action.headers['ExtraContext'].should be == Punchblock::Translator::Asterisk::REDIRECT_CONTEXT
            end
        end
      end
    end
  end
end
