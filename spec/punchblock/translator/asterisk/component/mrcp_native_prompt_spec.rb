# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe MRCPNativePrompt do
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

          let(:audio_filename) { 'http://example.com/hello.mp3' }

          let :output_command_options do
            { render_document: {value: [audio_filename], content_type: 'text/uri-list'} }.merge(output_command_opts)
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
          let(:recog_result)            { "%3C?xml%20version=%221.0%22?%3E%3Cresult%3E%0D%0A%3Cinterpretation%20grammar=%22session:grammar-0%22%20confidence=%220.43%22%3E%3Cinput%20mode=%22speech%22%3EHello%3C/input%3E%3Cinstance%3EHello%3C/instance%3E%3C/interpretation%3E%3C/result%3E" }

          subject { described_class.new original_command, mock_call }

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

          def expect_mrcprecog_with_options(options)
            expect_app_with_options 'MRCPRecog', options
          end

          def expect_app_with_options(app, options)
            mock_call.should_receive(:execute_agi_command).once.with do |*args|
              args[0].should be == "EXEC #{app}"
              args[1].should match options
            end.and_return code: 200, result: 1
          end

          describe 'Output#document' do
            context 'with multiple inline documents' do
              let(:output_command_options) { { render_documents: [{value: ssml_doc}, {value: ssml_doc}] } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'Only one document is allowed.'
                original_command.response(0.1).should be == error
              end
            end

            context 'with a document by URI' do
              let(:output_command_options) { { render_documents: [{url: 'http://example.com/doc1.ssml'}] } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'Only inline documents are allowed.'
                original_command.response(0.1).should be == error
              end
            end

            context 'with a urilist > size 1' do
              let(:output_command_options) { { render_documents: [{content_type: 'text/uri-list', value: ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3']}] } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'Only one audio file is allowed.'
                original_command.response(0.1).should be == error
              end
            end

            context 'unset' do
              let(:output_command_options) { {} }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A document is required.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#renderer' do
            [nil, :asterisk].each do |renderer|
              context renderer.to_s do
                let(:output_command_opts) { { renderer: renderer } }

                it "should return a ref and execute MRCPRecog" do
                  param = ["\"#{grammar.to_doc.to_s.squish.gsub('"', '\"')}\"", "uer=1&b=1&f=#{audio_filename}"].join(',')
                  mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPRecog', param).and_return code: 200, result: 1
                  subject.execute
                  original_command.response(0.1).should be_a Ref
                end

                context "when MRCPRecog completes" do
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
                      expected_complete_reason = Punchblock::Component::Input::Complete::NoInput.new component_id: subject.id, target_call_id: mock_call.id
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

            [:foobar, :swift, :unimrcp].each do |renderer|
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

          describe 'barge_in' do
            context 'unset' do
              let(:command_options) { { barge_in: nil } }

              it 'should pass the b=1 option to MRCPRecog' do
                expect_mrcprecog_with_options(/b=1/)
                subject.execute
              end
            end

            context 'true' do
              let(:command_options) { { barge_in: true } }

              it 'should pass the b=1 option to MRCPRecog' do
                expect_mrcprecog_with_options(/b=1/)
                subject.execute
              end
            end

            context 'false' do
              let(:command_options) { { barge_in: false } }

              it 'should pass the b=0 option to MRCPRecog' do
                expect_mrcprecog_with_options(/b=0/)
                subject.execute
              end
            end
          end

          describe 'Output#voice' do
            context 'unset' do
              let(:output_command_opts) { { voice: nil } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { voice: 'alison' } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Output#start-offset' do
            context 'unset' do
              let(:output_command_opts) { { start_offset: nil } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { start_offset: 10 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#start-paused' do
            context 'false' do
              let(:output_command_opts) { { start_paused: false } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'true' do
              let(:output_command_opts) { { start_paused: true } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#repeat-interval' do
            context 'unset' do
              let(:output_command_opts) { { repeat_interval: nil } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { repeat_interval: 10 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#repeat-times' do
            context 'unset' do
              let(:output_command_opts) { { repeat_times: nil } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { repeat_times: 2 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#max-time' do
            context 'unset' do
              let(:output_command_opts) { { max_time: nil } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { max_time: 30 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Output#interrupt_on' do
            context 'unset' do
              let(:output_command_opts) { { interrupt_on: nil } }
              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { interrupt_on: :dtmf } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A interrupt_on value is unsupported on Asterisk.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Input#grammar' do
            context 'with multiple inline grammars' do
              let(:input_command_options) { { grammars: [{value: voice_grammar}, {value: dtmf_grammar}] } }

              it "should return a ref and execute MRCPRecog" do
                param = ["\"#{[voice_grammar.to_doc.to_s, dtmf_grammar.to_doc.to_s].join(',').squish.gsub('"', '\"')}\"", "uer=1&b=1&f=#{audio_filename}"].join(',')
                mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPRecog', param).and_return code: 200, result: 1
                subject.execute
                original_command.response(0.1).should be_a Ref
              end
            end

            context 'with multiple grammars by URI' do
              let(:input_command_options) { { grammars: [{url: 'http://example.com/grammar1.grxml'}, {url: 'http://example.com/grammar2.grxml'}] } }

              it "should return a ref and execute MRCPRecog" do
                param = ["\"#{"http://example.com/grammar1.grxml,http://example.com/grammar2.grxml".squish.gsub('"', '\"')}\"", "uer=1&b=1&f=#{audio_filename}"].join(',')
                mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPRecog', param).and_return code: 200, result: 1
                subject.execute
                original_command.response(0.1).should be_a Ref
              end
            end

            context 'unset' do
              let(:input_command_options) { {} }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'A grammar is required.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Input#initial-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { initial_timeout: 1000 } }

              it 'should pass the nit option to MRCPRecog' do
                expect_mrcprecog_with_options(/nit=1000/)
                subject.execute
              end
            end

            context '-1' do
              let(:input_command_opts) { { initial_timeout: -1 } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { initial_timeout: nil } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'a negative number other than -1' do
              let(:input_command_opts) { { initial_timeout: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'An initial-timeout value must be -1 or a positive integer.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Input#inter-digit-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { inter_digit_timeout: 1000 } }

              it 'should pass the dit option to MRCPRecog' do
                expect_mrcprecog_with_options(/dit=1000/)
                subject.execute
              end
            end

            context '-1' do
              let(:input_command_opts) { { inter_digit_timeout: -1 } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { inter_digit_timeout: nil } }

              it 'should not pass any options to MRCPRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end

            context 'a negative number other than -1' do
              let(:input_command_opts) { { inter_digit_timeout: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'An inter-digit-timeout value must be -1 or a positive integer.'
                original_command.response(0.1).should be == error
              end
            end
          end

          describe 'Input#mode' do
            pending
          end

          describe 'Input#terminator' do
            context 'a string' do
              let(:input_command_opts) { { terminator: '#' } }

              it 'should pass the dttc option to SynthAndRecog' do
                expect_mrcprecog_with_options(/dttc=#/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { terminator: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_mrcprecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#recognizer' do
            pending
          end

          describe 'Input#sensitivity' do
            pending
          end

          describe 'Input#min-confidence' do
            pending
          end

          describe 'Input#max-silence' do
            pending
          end

          describe 'Input#match-content-type' do
            pending
          end

          describe 'Input#language' do
            pending
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
