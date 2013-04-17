# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Prompt do
          include HasMockCallbackConnection

          let(:media_engine)  { :unimrcp }
          let(:ami_client)    { mock('AMI') }
          let(:translator)    { Punchblock::Translator::Asterisk.new ami_client, connection, media_engine }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let :voice_grammar do
            RubySpeech::GRXML.draw :mode => 'voice', :root => 'color' do
              rule id: 'color' do
                one_of do
                  item { 'red' }
                  item { 'blue' }
                  item { 'green' }
                end
              end
            end
          end

          let :dtmf_grammar do
            RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'pin' do
              rule id: 'digit' do
                one_of do
                  0.upto(9) { |d| item { d.to_s } }
                end
              end

              rule id: 'pin', scope: 'public' do
                item repeat: '2' do
                  ruleref uri: '#digit'
                end
              end
            end
          end

          let(:grammar) { voice_grammar }

          let(:output_command_opts) { {} }

          let :output_command_options do
            { ssml: ssml_doc }.merge(output_command_opts)
          end

          let(:input_command_opts) { {} }

          let :input_command_options do
            { grammar: {value: grammar} }.merge(input_command_opts)
          end

          let(:command_options) { {} }

          let :output_command do
            Punchblock::Component::Output.new output_command_options
          end

          let :input_command do
            Punchblock::Component::Input.new input_command_options
          end

          let :original_command do
            Punchblock::Component::Prompt.new output_command, input_command, command_options
          end

          let(:recog_status)            { 'OK' }
          let(:recog_completion_cause)  { '000' }
          let(:recog_result)            { '<?xml version="1.0"?><result><interpretation grammar="session:grammar-0" confidence="0.43"><input mode="speech">Hello</input><instance>Hello</instance></interpretation></result>' }

          subject { Prompt.new original_command, mock_call }

          before do
            original_command.request!
            {
              'RECOG_STATUS' => recog_status,
              'RECOG_COMPLETION_CAUSE' => recog_completion_cause,
              'RECOG_RESULT' => recog_result
            }.each do |var, val|
              mock_call.stub(:channel_var).with(var).and_return val
            end
          end

          context 'with an invalid recognizer' do
            let(:input_command_opts) { { recognizer: 'foobar' } }

            it "should return an error and not execute any actions" do
              subject.execute
              error = ProtocolError.new.setup 'option error', 'The recognizer foobar is unsupported.'
              original_command.response(0.1).should be == error
            end
          end

          [:asterisk].each do |recognizer|
            context "with a recognizer #{recognizer.inspect}" do
              let(:input_command_opts) { { recognizer: recognizer } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', "The recognizer #{recognizer} is unsupported."
                original_command.response(0.1).should be == error
              end
            end
          end

          def expect_mrcpsynth_with_options(options)
            expect_app_with_options 'MRCPSynth', options
          end

          def expect_synthandrecog_with_options(options)
            expect_app_with_options 'SynthAndRecog', options
          end

          def expect_app_with_options(app, options)
            mock_call.should_receive(:execute_agi_command).once.with do |*args|
              args[0].should be == "EXEC #{app}"
              args[2].should match options
            end.and_return code: 200, result: 1
          end

          describe 'Output#document' do
            context 'unset' do
              let(:output_command_opts) { { ssml: nil } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#renderer' do
            [nil, :unimrcp].each do |renderer|
              context renderer.to_s do
                let(:output_command_opts) { { renderer: renderer } }

                it "should return a ref and execute SynthAndRecog" do
                  param = [ssml_doc.to_doc, grammar.to_doc, nil].map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.join(',')
                  mock_call.should_receive(:execute_agi_command).once.with('EXEC SynthAndRecog', param).and_return code: 200, result: 1
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                context "when SynthAndRecog completes" do
                  context "with a match" do
                    let :expected_nlsml do
                      RubySpeech::NLSML.draw do
                        interpretation grammar: 'session:grammar-0', confidence: 0.43 do
                          input 'Hello', mode: :speech
                          instance 'Hello'
                        end
                      end
                    end

                    it 'should send a match complete event' do
                      expected_complete_reason = Punchblock::Component::Input::Complete::Match.new nlsml: expected_nlsml,
                        component_id: subject.id,
                        target_call_id: mock_call.id

                      mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      original_command.complete_event(0.1).reason.should == expected_complete_reason
                    end
                  end

                  context "with a nomatch cause" do
                    let(:recog_completion_cause) { '001' }

                    it 'should send a nomatch complete event' do
                      expected_complete_reason = Punchblock::Component::Input::Complete::NoMatch.new component_id: subject.id, target_call_id: mock_call.id
                      mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      original_command.complete_event(0.1).reason.should == expected_complete_reason
                    end
                  end

                  context "with a noinput cause" do
                    let(:recog_completion_cause) { '002' }

                    it 'should send a nomatch complete event' do
                      expected_complete_reason = Punchblock::Component::Input::Complete::InitialTimeout.new component_id: subject.id, target_call_id: mock_call.id
                      mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      original_command.complete_event(0.1).reason.should == expected_complete_reason
                    end
                  end

                  context "when the RECOG_STATUS variable is set to 'ERROR'" do
                    let(:recog_status) { 'ERROR' }

                    it "should send an error complete event" do
                      mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      complete_reason = original_command.complete_event(0.1).reason
                      complete_reason.should be_a Punchblock::Event::Complete::Error
                      complete_reason.details.should == "Terminated due to UniMRCP error"
                    end
                  end
                end

                context "when we get a RubyAMI Error" do
                  it "should send an error complete event" do
                    error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                    mock_call.should_receive(:execute_agi_command).and_raise error
                    subject.execute
                    complete_reason = original_command.complete_event(0.1).reason
                    complete_reason.should be_a Punchblock::Event::Complete::Error
                    complete_reason.details.should == "Terminated due to AMI error 'FooBar'"
                  end
                end
              end
            end

            [:foobar, :swift, :asterisk].each do |renderer|
              context renderer do
                let(:output_command_opts) { { renderer: renderer } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', "The renderer #{renderer} is unsupported."
                  original_command.response(0.1).should be == error
                end
              end
            end
          end

          describe "#execute_command" do
            context "with a command it does not understand" do
              let(:command) { Punchblock::Component::Output::Pause.new }

              before { command.request! }
              it "returns a ProtocolError response" do
                subject.execute_command command
                command.response(0.1).should be_a ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Punchblock::Component::Stop.new }
              let(:reason) { original_command.complete_event(5).reason }
              let(:channel) { "SIP/1234-00000000" }
              let :ami_event do
                RubyAMI::Event.new 'AsyncAGI',
                  'SubEvent'  => "Start",
                  'Channel'   => channel,
                  'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before do
                command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                mock_call.async.should_receive(:redirect_back)
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                mock_call.async.should_receive(:redirect_back)
                subject.execute_command command
                original_command.should_not be_complete
                mock_call.process_ami_event ami_event
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end

              it "redirects the call by unjoining it" do
                mock_call.async.should_receive(:redirect_back)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
