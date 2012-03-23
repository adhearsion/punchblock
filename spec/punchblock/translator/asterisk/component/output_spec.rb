# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Output do
          let(:connection) do
            mock_connection_with_event_handler do |event|
              command.add_event event
            end
          end
          let(:media_engine)  { nil }
          let(:translator)    { Punchblock::Translator::Asterisk.new mock('AMI'), connection, media_engine }
          let(:mock_call)     { Punchblock::Translator::Asterisk::Call.new 'foo', translator }

          let :command do
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

          subject { Output.new command, mock_call }

          describe '#execute' do
            before { command.request! }

            it "calls answer_if_not_answered on the call" do
              mock_call.expects :answer_if_not_answered
              subject.execute
            end

            before { mock_call.stubs :answer_if_not_answered }

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
                command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
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
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options('', '|1|1')
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should add the interrupt options to the argument" do
                    mock_call.expects(:send_agi_action!).once.with 'EXEC Swift', ssml_with_options('', '|1|1')
                    subject.execute
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    command.response(0.1).should be == error
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

              it 'should send a complete event when MRCPSynth completes' do
                def mock_call.send_agi_action!(*args, &block)
                  block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                end
                subject.execute
                command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
              end

              describe 'ssml' do
                context 'unset' do
                  let(:command_opts) { { :ssml => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    command.response(0.1).should be == error
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
                    command.response(0.1).should be == error
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
                    command.response(0.1).should be == error
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
                    command.response(0.1).should be == error
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
                    command.response(0.1).should be == error
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
                    command.response(0.1).should be == error
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
                    expect_mrcpsynth_with_options(/i=any/)
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should pass the i option to MRCPSynth" do
                    expect_mrcpsynth_with_options(/i=any/)
                    subject.execute
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    command.response(0.1).should be == error
                  end
                end
              end
            end

            context 'with a media engine of :asterisk' do
              let(:media_engine) { :asterisk }

              def expect_stream_file_with_options(options = nil)
                mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename, options do |*args|
                  args[2].should be == options
                  subject.continue!
                  true
                end
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

              let :command do
                Punchblock::Component::Output.new command_options
              end

              describe 'ssml' do
                context 'unset' do
                  let(:command_opts) { { :ssml => nil } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    command.response(0.1).should be == error
                  end
                end

                context 'with a single audio SSML node' do
                  let(:audio_filename) { 'http://foo.com/bar.mp3' }
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw { audio :src => audio_filename }
                    }
                  end

                  it 'should playback the audio file using STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end

                  it 'should send a complete event when the file finishes playback' do
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    subject.execute
                    command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
                  end
                end

                context 'with a single text node without spaces' do
                  let(:audio_filename) { 'tt-monkeys' }
                  let :command_options do
                    {
                      :ssml => RubySpeech::SSML.draw { string audio_filename }
                    }
                  end

                  it 'should playback the audio file using STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end

                  it 'should send a complete event when the file finishes playback' do
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    subject.execute
                    command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
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

                  it 'should playback each audio file using STREAM FILE' do
                    latch = CountDownLatch.new 2
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename1, nil do
                      subject.continue
                      latch.countdown!
                    end
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename2, nil do
                      subject.continue
                      latch.countdown!
                    end
                    subject.execute
                    latch.wait 2
                    sleep 2
                  end

                  it 'should send a complete event after the final file has finished playback' do
                    def mock_call.send_agi_action!(*args, &block)
                      block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                    end
                    command.expects(:add_event).once.with do |e|
                      e.reason.should be_a Punchblock::Component::Output::Complete::Success
                    end
                    subject.execute
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
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-offset' do
                context 'unset' do
                  let(:command_opts) { { :start_offset => nil } }
                  it 'should not pass any options to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :start_offset => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'start-paused' do
                context 'false' do
                  let(:command_opts) { { :start_paused => false } }
                  it 'should not pass any options to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'true' do
                  let(:command_opts) { { :start_paused => true } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-interval' do
                context 'unset' do
                  let(:command_opts) { { :repeat_interval => nil } }
                  it 'should not pass any options to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_interval => 10 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'repeat-times' do
                context 'unset' do
                  let(:command_opts) { { :repeat_times => nil } }
                  it 'should not pass any options to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :repeat_times => 2 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'max-time' do
                context 'unset' do
                  let(:command_opts) { { :max_time => nil } }
                  it 'should not pass any options to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :max_time => 30 } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'voice' do
                context 'unset' do
                  let(:command_opts) { { :voice => nil } }
                  it 'should not pass the v option to STREAM FILE' do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context 'set' do
                  let(:command_opts) { { :voice => 'alison' } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'A voice value is unsupported on Asterisk.'
                    command.response(0.1).should be == error
                  end
                end
              end

              describe 'interrupt_on' do
                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "should not pass any digits to STREAM FILE" do
                    expect_stream_file_with_options
                    subject.execute
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }
                  it "should pass all digits to STREAM FILE" do
                    expect_stream_file_with_options '0123456789*#'
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should pass all digits to STREAM FILE" do
                    expect_stream_file_with_options '0123456789*#'
                    subject.execute
                  end
                end

                context "set to :speech" do
                  let(:command_opts) { { :interrupt_on => :speech } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    command.response(0.1).should be == error
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
