# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Output do
          let(:connection) do
            mock_connection_with_event_handler do |event|
              original_command.add_event event
            end
          end
          let(:media_engine)  { nil }
          let(:translator)    { Punchblock::Translator::Asterisk.new mock('AMI'), connection, media_engine }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new 'foo', translator }

          let :original_command do
            Punchblock::Component::Output.new command_options
          end

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let :command_options do
            { :ssml => ssml_doc }
          end

          subject { Output.new original_command, mock_call }

          def expect_answered(value = true)
            mock_call.expects(:answered?).returns(value).at_least_once
          end

          describe '#execute' do
            before { original_command.request! }

            context 'with a media engine of :swift' do
              let(:media_engine) { :swift }

              let(:audio_filename) { 'http://foo.com/bar.mp3' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename
                  say_as(:interpret_as => :cardinal) { 'FOO' }
                end
              end

              let(:command_opts) { {} }

              let :command_options do
                { :ssml => ssml_doc }.merge(command_opts)
              end

              def ssml_with_options(prefix = '', postfix = '')
                base_doc = ssml_doc.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
                prefix + base_doc + postfix
              end

              it "should execute Swift" do
                mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options
                subject.execute
              end

              it 'should send a complete event when Swift completes' do
                def mock_call.send_agi_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                end
                subject.execute
                original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
              end

              describe 'interrupt_on' do
                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "should not add interrupt arguments" do
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options
                    subject.execute
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }
                  it "should add the interrupt options to the argument" do
                    expect_answered
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options('', '|1|1')
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should add the interrupt options to the argument" do
                    expect_answered
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options('', '|1|1')
                    subject.execute
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'voice' do
                context "set to nil" do
                  let(:command_opts) { { :voice => nil } }
                  it "should not add a voice at the beginning of the argument" do
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options
                    subject.execute
                  end
                end

                context "set to Leonard" do
                  let(:command_opts) { { :voice => "Leonard" } }
                  it "should add a voice at the beginning of the argument" do
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options('Leonard^', '')
                    subject.execute
                  end
                end

              end
            end

            context 'with a media engine of :unimrcp' do
              let(:media_engine) { :unimrcp }

              let(:audio_filename) { 'http://foo.com/bar.mp3' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename
                  say_as(:interpret_as => :cardinal) { 'FOO' }
                end
              end

              let(:command_opts) { {} }

              let :command_options do
                { :ssml => ssml_doc }.merge(command_opts)
              end

              def expect_mrcpsynth_with_options(options)
                mock_call.expects(:send_agi_action!).once.with do |*args|
                  args[0].should be == 'EXEC MRCPSynth'
                  args[2].should match options
                end
              end

              it "should execute MRCPSynth" do
                mock_call.expects(:send_agi_action!).once.with 'EXEC MRCPSynth', ssml_doc.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }, ''
                subject.execute
              end

              context "when the SSML document contains commas" do
                let :ssml_doc do
                  RubySpeech::SSML.draw do
                    string "this, here, is a test"
                  end
                end

                it 'should escape TTS strings containing a comma' do
                  mock_call.expects(:send_agi_action!).once.with do |*args|
                    args[0].should be == 'EXEC MRCPSynth'
                    args[1].should match(/this\\, here\\, is a test/)
                  end
                  subject.execute
                end
              end

              it 'should send a complete event when MRCPSynth completes' do
                def mock_call.send_agi_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                end
                subject.execute
                original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
              end

              describe 'ssml' do
                context 'unset' do
                  let(:command_opts) { { :ssml => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-offset' do
                context 'unset' do
                  let(:command_opts) { { :start_offset => nil } }
                  it 'should not pass any options to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :start_offset => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-paused' do
                context 'false' do
                  let(:command_opts) { { :start_paused => false } }
                  it 'should not pass any options to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'true' do
                  let(:command_opts) { { :start_paused => true } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-interval' do
                context 'unset' do
                  let(:command_opts) { { :repeat_interval => nil } }
                  it 'should not pass any options to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_interval => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-times' do
                context 'unset' do
                  let(:command_opts) { { :repeat_times => nil } }
                  it 'should not pass any options to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_times => 2 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'max-time' do
                context 'unset' do
                  let(:command_opts) { { :max_time => nil } }
                  it 'should not pass any options to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :max_time => 30 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'voice' do
                context 'unset' do
                  let(:command_opts) { { :voice => nil } }
                  it 'should not pass the v option to MRCPSynth' do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :voice => 'alison' } }
                  it 'should pass the v option to MRCPSynth' do
                    expect_mrcpsynth_with_options(/v=alison/)
                    subject.execute
                  end
                end
              end

              describe 'interrupt_on' do
                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "should not pass the i option to MRCPSynth" do
                    expect_mrcpsynth_with_options(//)
                    subject.execute
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }
                  it "should pass the i option to MRCPSynth" do
                    expect_answered
                    expect_mrcpsynth_with_options(/i=any/)
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should pass the i option to MRCPSynth" do
                    expect_answered
                    expect_mrcpsynth_with_options(/i=any/)
                    subject.execute
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    original_command.response(0.1).should be == error
                  end
                end
              end
            end

            context 'with a media engine of :asterisk' do
              let(:media_engine) { :asterisk }

              def expect_playback(filename = audio_filename)
                mock_call.expects(:send_agi_action!).once.with 'EXEC Playback', filename
              end

              def expect_playback_noanswer
                mock_call.expects(:send_agi_action!).once.with 'EXEC Playback', audio_filename + ',noanswer'
              end

              let(:audio_filename) { 'http://foo.com/bar.mp3' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename
                end
              end

              let(:command_opts) { {} }

              let :command_options do
                { :ssml => ssml_doc }.merge(command_opts)
              end

              let :original_command do
                Punchblock::Component::Output.new command_options
              end

              describe 'ssml' do
                context 'unset' do
                  let(:command_opts) { { :ssml => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    original_command.response(0.1).should be == error
                  end
                end

                context 'with a single audio SSML node' do
                  let(:audio_filename) { 'http://foo.com/bar.mp3' }
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw { audio :src => audio_filename }
                    }
                  end

                  it 'should playback the audio file using Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end

                  it 'should send a complete event when the file finishes playback' do
                    def mock_call.answered?
                      true
                    end
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    subject.execute
                    original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
                  end
                end

                context 'with a single text node without spaces' do
                  let(:audio_filename) { 'tt-monkeys' }
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw { string audio_filename }
                    }
                  end

                  it 'should playback the audio file using Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end

                  it 'should send a complete event when the file finishes playback' do
                    expect_answered
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    subject.execute
                    original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
                  end

                  context "with early media playback" do
                    it "should play the file with Playback" do
                      expect_answered false
                      expect_playback_noanswer
                      mock_call.expects(:send_progress)
                      subject.execute
                    end

                    context "with interrupt_on set to something that is not nil" do
                      let(:audio_filename) { 'tt-monkeys' }
                      let :command_options do
                        {
                          :ssml => RubySpeech::SSML.draw { string audio_filename },
                          :interrupt_on => :any
                        }
                      end
                      it "should return an error when the output is interruptible and it is early media" do
                        expect_answered false
                        error = ProtocolError.new.setup 'option error', 'Interrupt digits are not allowed with early media.'
                        subject.execute
                        original_command.response(0.1).should be == error
                      end
                    end
                  end
                end

                context 'with a string (not SSML)' do
                  let :command_options do
                    { :text => 'Foo Bar' }
                  end

                  it "should return an unrenderable document error" do
                    subject.execute
                    error = ProtocolError.new.setup 'unrenderable document error', 'The provided document could not be rendered.'
                    original_command.response(0.1).should be == error
                  end
                end

                context 'with multiple audio SSML nodes' do
                  let(:audio_filename1) { 'http://foo.com/bar.mp3' }
                  let(:audio_filename2) { 'http://foo.com/baz.mp3' }
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw do
                        audio :src => audio_filename1
                        audio :src => audio_filename2
                      end
                    }
                  end

                  it 'should playback all audio files using Playback' do
                    latch = CountDownLatch.new 2
                    expect_playback [audio_filename1, audio_filename2].join('&')
                    expect_answered
                    subject.execute
                    latch.wait 2
                    sleep 2
                  end

                  it 'should send a complete event after the final file has finished playback' do
                    expect_answered
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    latch = CountDownLatch.new 1
                    original_command.expects(:add_event).once.with do |e|
                      e.reason.should be_a Punchblock::Component::Output::Complete::Success
                      latch.countdown!
                    end
                    subject.execute
                    latch.wait(2).should be_true
                  end
                end

                context "with an SSML document containing elements other than <audio/>" do
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw do
                        string "Foo Bar"
                      end
                    }
                  end

                  it "should return an unrenderable document error" do
                    subject.execute
                    error = ProtocolError.new.setup 'unrenderable document error', 'The provided document could not be rendered.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-offset' do
                context 'unset' do
                  let(:command_opts) { { :start_offset => nil } }
                  it 'should not pass any options to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :start_offset => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-paused' do
                context 'false' do
                  let(:command_opts) { { :start_paused => false } }
                  it 'should not pass any options to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'true' do
                  let(:command_opts) { { :start_paused => true } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-interval' do
                context 'unset' do
                  let(:command_opts) { { :repeat_interval => nil } }
                  it 'should not pass any options to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_interval => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-times' do
                context 'unset' do
                  let(:command_opts) { { :repeat_times => nil } }
                  it 'should not pass any options to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_times => 2 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'max-time' do
                context 'unset' do
                  let(:command_opts) { { :max_time => nil } }
                  it 'should not pass any options to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :max_time => 30 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'voice' do
                context 'unset' do
                  let(:command_opts) { { :voice => nil } }
                  it 'should not pass the v option to Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :voice => 'alison' } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A voice value is unsupported on Asterisk.'
                    original_command.response(0.1).should be == error
                  end
                end
              end

              describe 'interrupt_on' do
                def ami_event_for_dtmf(digit, position)
                  RubyAMI::Event.new('DTMF').tap do |e|
                    e['Digit']  = digit.to_s
                    e['Start']  = position == :start ? 'Yes' : 'No'
                    e['End']    = position == :end ? 'Yes' : 'No'
                  end
                end

                def send_ami_events_for_dtmf(digit)
                  mock_call.process_ami_event ami_event_for_dtmf(digit, :start)
                  mock_call.process_ami_event ami_event_for_dtmf(digit, :end)
                end

                let(:reason) { original_command.complete_event(5).reason }
                let(:channel) { "SIP/1234-00000000" }
                let :ami_event do
                  RubyAMI::Event.new('AsyncAGI').tap do |e|
                    e['SubEvent'] = "Start"
                    e['Channel']  = channel
                    e['Env']      = "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
                  end
                end

                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "does not redirect the call" do
                    expect_answered
                    expect_playback
                    mock_call.expects(:redirect_back!).never
                    subject.execute
                    original_command.response(0.1).should be_a Ref
                    send_ami_events_for_dtmf 1
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }

                  before do
                    expect_answered
                    expect_playback
                  end

                  context "when a DTMF digit is received" do
                    it "sends the correct complete event" do
                      mock_call.expects :redirect_back!
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      original_command.should_not be_complete
                      send_ami_events_for_dtmf 1
                      mock_call.process_ami_event! ami_event
                      sleep 0.2
                      original_command.should be_complete
                      reason.should be_a Punchblock::Component::Output::Complete::Success
                    end

                    it "redirects the call back to async AGI" do
                      mock_call.expects(:redirect_back!).with(nil).once
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      send_ami_events_for_dtmf 1
                    end
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }

                  before do
                    expect_answered
                    expect_playback
                  end

                  context "when a DTMF digit is received" do
                    it "sends the correct complete event" do
                      mock_call.expects :redirect_back!
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      original_command.should_not be_complete
                      send_ami_events_for_dtmf 1
                      mock_call.process_ami_event! ami_event
                      sleep 0.2
                      original_command.should be_complete
                      reason.should be_a Punchblock::Component::Output::Complete::Success
                    end

                    it "redirects the call back to async AGI" do
                      mock_call.expects(:redirect_back!).with(nil).once
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      send_ami_events_for_dtmf 1
                    end
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    original_command.response(0.1).should be == error
                  end
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
                RubyAMI::Event.new('AsyncAGI').tap do |e|
                  e['SubEvent'] = "Start"
                  e['Channel']  = channel
                  e['Env']      = "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
                end
              end

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                mock_call.expects(:redirect_back!)
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                mock_call.expects(:redirect_back!)
                subject.execute_command command
                original_command.should_not be_complete
                mock_call.process_ami_event! ami_event
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end

              it "redirects the call by unjoining it" do
                mock_call.expects(:redirect_back!).with(nil)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
