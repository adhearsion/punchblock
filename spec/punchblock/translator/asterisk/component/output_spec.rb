# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe Output do
          include HasMockCallbackConnection

          let(:renderer)    { nil }
          let(:ami_client)  { double('AMI') }
          let(:translator)  { Punchblock::Translator::Asterisk.new ami_client, connection }
          let(:mock_call)   { Punchblock::Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }

          let :original_command do
            Punchblock::Component::Output.new command_options
          end

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let(:command_opts) { {} }

          let :command_options do
            { :render_document => {:value => ssml_doc}, renderer: renderer }
          end

          subject { Output.new original_command, mock_call }

          def expect_answered(value = true)
            mock_call.stub(:answered?).and_return(value)
          end

          def expect_mrcpsynth_with_options(options)
            mock_call.should_receive(:execute_agi_command).once.with do |*args|
              args[0].should be == 'EXEC MRCPSynth'
              args[1].should match options
            end.and_return code: 200, result: 1
          end

          describe '#execute' do
            before { original_command.request! }

            context 'with an invalid renderer' do
              let(:renderer) { 'foobar' }

              it "should return an error and not execute any actions" do
                subject.execute
                error = ProtocolError.new.setup 'option error', 'The renderer foobar is unsupported.'
                original_command.response(0.1).should be == error
              end
            end

            context 'with a renderer of :swift' do
              let(:renderer) { 'swift' }

              let(:audio_filename) { 'http://foo.com/bar.mp3' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename
                  say_as(:interpret_as => :cardinal) { 'FOO' }
                end
              end

              let :command_options do
                { :render_document => {:value => ssml_doc}, renderer: renderer }.merge(command_opts)
              end

              def ssml_with_options(prefix = '', postfix = '')
                base_doc = ssml_doc.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
                prefix + base_doc + postfix
              end

              before { expect_answered }

              it "should execute Swift" do
                mock_call.should_receive(:execute_agi_command).once.with 'EXEC Swift', ssml_with_options
                subject.execute
              end

              it 'should send a complete event when Swift completes' do
                mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                subject.execute
                original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
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

              context "when the channel is gone" do
                it "should send an error complete event" do
                  error = ChannelGoneError.new 'FooBar'
                  mock_call.should_receive(:execute_agi_command).and_raise error
                  subject.execute
                  complete_reason = original_command.complete_event(0.1).reason
                  complete_reason.should be_a Punchblock::Event::Complete::Hangup
                end
              end

              context "when the call is not answered" do
                before { expect_answered false }

                it "should send progress" do
                  mock_call.should_receive(:send_progress)
                  mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                  subject.execute
                end
              end

              describe 'interrupt_on' do
                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "should not add interrupt arguments" do
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Swift', ssml_with_options).and_return code: 200, result: 1
                    subject.execute
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }
                  it "should add the interrupt options to the argument" do
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Swift', ssml_with_options('', '|1|1')).and_return code: 200, result: 1
                    subject.execute
                  end
                end

                context "set to :dtmf" do
                  let(:command_opts) { { :interrupt_on => :dtmf } }
                  it "should add the interrupt options to the argument" do
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Swift', ssml_with_options('', '|1|1')).and_return code: 200, result: 1
                    subject.execute
                  end
                end

                context "set to :voice" do
                  let(:command_opts) { { :interrupt_on => :voice } }
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
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Swift', ssml_with_options).and_return code: 200, result: 1
                    subject.execute
                  end
                end

                context "set to Leonard" do
                  let(:command_opts) { { :voice => "Leonard" } }
                  it "should add a voice at the beginning of the argument" do
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Swift', ssml_with_options('Leonard^', '')).and_return code: 200, result: 1
                    subject.execute
                  end
                end

              end

              describe "with multiple documents" do
                let :first_ssml_doc do
                  RubySpeech::SSML.draw do
                    audio :src => audio_filename
                  end
                end
                let :second_ssml_doc do
                  RubySpeech::SSML.draw do
                    say_as(:interpret_as => :cardinal) { 'FOO' }
                  end
                end
                let(:command_opts) { { render_documents: [{value: first_ssml_doc}, {value: second_ssml_doc}] } }

                it "executes Swift with a concatenated version of the documents" do
                  mock_call.should_receive(:execute_agi_command).once.with 'EXEC Swift', ssml_with_options
                  subject.execute
                end
              end
            end

            context 'with a renderer of :unimrcp' do
              let(:renderer) { :unimrcp }

              let(:audio_filename) { 'http://foo.com/bar.mp3' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename
                  say_as(:interpret_as => :cardinal) { 'FOO' }
                end
              end

              let(:command_opts) { {} }

              let :command_options do
                { :render_document => {:value => ssml_doc}, renderer: renderer }.merge(command_opts)
              end

              let(:synthstatus) { 'OK' }
              before { mock_call.stub(:channel_var).with('SYNTHSTATUS').and_return synthstatus }

              before { expect_answered }

              it "should execute MRCPSynth" do
                mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPSynth', ["\"#{ssml_doc.to_s.squish.gsub('"', '\"')}\"", ''].join(',')).and_return code: 200, result: 1
                subject.execute
              end

              it 'should send a complete event when MRCPSynth completes' do
                mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                subject.execute
                original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
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

              context "when the channel is gone" do
                it "should send an error complete event" do
                  error = ChannelGoneError.new 'FooBar'
                  mock_call.should_receive(:execute_agi_command).and_raise error
                  subject.execute
                  complete_reason = original_command.complete_event(0.1).reason
                  complete_reason.should be_a Punchblock::Event::Complete::Hangup
                end
              end

              context "when the call is not answered" do
                before { expect_answered false }

                it "should send progress" do
                  mock_call.should_receive(:send_progress)
                  mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                  subject.execute
                end
              end

              context "when the SYNTHSTATUS variable is set to 'ERROR'" do
                let(:synthstatus) { 'ERROR' }

                it "should send an error complete event" do
                  mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                  subject.execute
                  complete_reason = original_command.complete_event(0.1).reason
                  complete_reason.should be_a Punchblock::Event::Complete::Error
                  complete_reason.details.should == "Terminated due to UniMRCP error"
                end
              end

              describe 'document' do
                context 'unset' do
                  let(:ssml_doc) { nil }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    original_command.response(0.1).should be == error
                  end
                end

                context 'with multiple documents' do
                  let(:command_opts) { { :render_documents => [{:value => ssml_doc}, {:value => ssml_doc}] } }

                  it "should execute MRCPSynth once with each document" do
                    param = ["\"#{ssml_doc.to_s.squish.gsub('"', '\"')}\"", ''].join(',')
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPSynth', param).and_return code: 200, result: 1
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC MRCPSynth', param).and_return code: 200, result: 1
                    subject.execute
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

                context "set to :voice" do
                  let(:command_opts) { { :interrupt_on => :voice } }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                    original_command.response(0.1).should be == error
                  end
                end
              end
            end

            [:asterisk, nil].each do |renderer|
              context "with a renderer of #{renderer.inspect}" do
                def expect_playback(filename = audio_filename)
                  mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', filename).and_return code: 200
                end

                def expect_playback_noanswer
                  mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename + ',noanswer').and_return code: 200
                end

                let(:audio_filename) { 'tt-monkeys' }

                let :ssml_doc do
                  RubySpeech::SSML.draw do
                    audio :src => audio_filename
                  end
                end

                let(:command_opts) { {} }

                let :command_options do
                  { :render_document => {:value => ssml_doc}, renderer: renderer }.merge(command_opts)
                end

                let :original_command do
                  Punchblock::Component::Output.new command_options
                end

                let(:playbackstatus) { 'SUCCESS' }
                before { mock_call.stub(:channel_var).with('PLAYBACKSTATUS').and_return playbackstatus }

                describe 'ssml' do
                  context 'unset' do
                    let(:ssml_doc) { nil }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                      original_command.response(0.1).should be == error
                    end
                  end

                  context 'with a single audio SSML node' do
                    let(:audio_filename) { 'tt-monkeys' }
                    let :ssml_doc do
                      RubySpeech::SSML.draw { audio :src => audio_filename }
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
                      expect_playback
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "when the audio filename is prefixed by file://" do
                      let(:audio_filename) { 'file://tt-monkeys' }

                      it 'should playback the audio file using Playback' do
                        expect_answered
                        expect_playback 'tt-monkeys'
                        subject.execute
                      end
                    end

                    context "when the audio filename has an extension" do
                      let(:audio_filename) { 'tt-monkeys.wav' }

                      it 'should playback the audio file using Playback' do
                        expect_answered
                        expect_playback 'tt-monkeys'
                        subject.execute
                      end

                      context "when there are other dots in the filename" do
                        let(:audio_filename) { 'blue.tt-monkeys.wav' }

                        it 'should playback the audio file using Playback' do
                          expect_answered
                          expect_playback 'blue.tt-monkeys'
                          subject.execute
                        end
                      end
                    end

                    context "when we get a RubyAMI Error" do
                      it "should send an error complete event" do
                        expect_answered
                        error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                        mock_call.should_receive(:execute_agi_command).and_raise error
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to AMI error 'FooBar'"
                      end
                    end

                    context "when the channel is gone" do
                      it "should send an error complete event" do
                        expect_answered
                        error = ChannelGoneError.new 'FooBar'
                        mock_call.should_receive(:execute_agi_command).and_raise error
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Hangup
                      end
                    end

                    context "when the PLAYBACKSTATUS variable is set to 'FAILED'" do
                      let(:playbackstatus) { 'FAILED' }

                      it "should send an error complete event" do
                        expect_answered
                        mock_call.should_receive(:execute_agi_command).and_return code: 200, result: 1
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to playback error"
                      end
                    end
                  end

                  context 'with a single text node without spaces' do
                    let(:audio_filename) { 'tt-monkeys' }
                    let :ssml_doc do
                      RubySpeech::SSML.draw { string audio_filename }
                    end

                    it 'should playback the audio file using Playback' do
                      expect_answered
                      expect_playback
                      subject.execute
                    end

                    it 'should send a complete event when the file finishes playback' do
                      expect_answered
                      expect_playback
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "when we get a RubyAMI Error" do
                      it "should send an error complete event" do
                        expect_answered
                        error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                        mock_call.should_receive(:execute_agi_command).and_raise error
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to AMI error 'FooBar'"
                      end
                    end

                    context "with early media playback" do
                      it "should play the file with Playback" do
                        expect_answered false
                        expect_playback_noanswer
                        mock_call.should_receive(:send_progress)
                        subject.execute
                      end

                      context "with interrupt_on set to something that is not nil" do
                        let(:audio_filename) { 'tt-monkeys' }
                        let :command_options do
                          {
                            :render_document => {
                              :value => RubySpeech::SSML.draw { string audio_filename },
                            },
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

                  context 'with multiple audio SSML nodes' do
                    let(:audio_filename1) { 'foo' }
                    let(:audio_filename2) { 'bar' }
                    let :ssml_doc do
                      RubySpeech::SSML.draw do
                        audio :src => audio_filename1
                        audio :src => audio_filename2
                      end
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
                      expect_playback [audio_filename1, audio_filename2].join('&')
                      latch = CountDownLatch.new 1
                      original_command.should_receive(:add_event).once.with do |e|
                        e.reason.should be_a Punchblock::Component::Output::Complete::Finish
                        latch.countdown!
                      end
                      subject.execute
                      latch.wait(2).should be_true
                    end
                  end

                  context "with an SSML document containing elements other than <audio/>" do
                    let :ssml_doc do
                      RubySpeech::SSML.draw do
                        string "Foo Bar"
                      end
                    end

                    it "should return an unrenderable document error" do
                      subject.execute
                      error = ProtocolError.new.setup 'unrenderable document error', 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.'
                      original_command.response(0.1).should be == error
                    end
                  end

                  context 'with multiple documents' do
                    let(:command_opts) { { render_documents: [{value: ssml_doc}, {value: ssml_doc}] } }

                    it "should render each document in turn using a Playback per document" do
                      expect_answered
                      2.times { expect_playback }
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "when the PLAYBACKSTATUS variable is set to 'FAILED'" do
                      let(:playbackstatus) { 'FAILED' }

                      it "should terminate playback and send an error complete event" do
                        expect_answered
                        mock_call.should_receive(:execute_agi_command).once.and_return code: 200, result: 1
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to playback error"
                      end
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
                    RubyAMI::Event.new 'DTMF',
                      'Digit' => digit.to_s,
                      'Start' => position == :start ? 'Yes' : 'No',
                      'End'   => position == :end ? 'Yes' : 'No'
                  end

                  def send_ami_events_for_dtmf(digit)
                    mock_call.process_ami_event ami_event_for_dtmf(digit, :start)
                    mock_call.process_ami_event ami_event_for_dtmf(digit, :end)
                  end

                  let(:reason) { original_command.complete_event(5).reason }
                  let(:channel) { "SIP/1234-00000000" }
                  let :ami_event do
                    RubyAMI::Event.new 'AsyncAGI',
                      'SubEvent'  => "Start",
                      'Channel'   => channel,
                      'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
                  end

                  context "set to nil" do
                    let(:command_opts) { { :interrupt_on => nil } }
                    it "does not redirect the call" do
                      expect_answered
                      expect_playback
                      mock_call.async.should_receive(:redirect_back).never
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      send_ami_events_for_dtmf 1
                    end
                  end

                  context "set to :any" do
                    let(:command_opts) { { :interrupt_on => :any } }

                    before do
                      expect_answered
                      mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename)
                      subject.wrapped_object.should_receive(:send_finish).and_return nil
                    end

                    context "when a DTMF digit is received" do
                      it "sends the correct complete event" do
                        mock_call.async.should_receive :redirect_back
                        subject.execute
                        original_command.response(0.1).should be_a Ref
                        original_command.should_not be_complete
                        send_ami_events_for_dtmf 1
                        mock_call.async.process_ami_event ami_event
                        sleep 0.2
                        original_command.should be_complete
                        reason.should be_a Punchblock::Component::Output::Complete::Finish
                      end

                      it "redirects the call back to async AGI" do
                        mock_call.async.should_receive(:redirect_back).once
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
                      mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename)
                      subject.wrapped_object.should_receive(:send_finish).and_return nil
                    end

                    context "when a DTMF digit is received" do
                      it "sends the correct complete event" do
                        mock_call.async.should_receive :redirect_back
                        subject.execute
                        original_command.response(0.1).should be_a Ref
                        original_command.should_not be_complete
                        send_ami_events_for_dtmf 1
                        mock_call.async.process_ami_event ami_event
                        sleep 0.2
                        original_command.should be_complete
                        reason.should be_a Punchblock::Component::Output::Complete::Finish
                      end

                      it "redirects the call back to async AGI" do
                        mock_call.async.should_receive(:redirect_back).once
                        subject.execute
                        original_command.response(0.1).should be_a Ref
                        send_ami_events_for_dtmf 1
                      end
                    end
                  end

                  context "set to :voice" do
                    let(:command_opts) { { :interrupt_on => :voice } }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new.setup 'option error', 'An interrupt-on value of speech is unsupported.'
                      original_command.response(0.1).should be == error
                    end
                  end
                end
              end
            end

            context "with a renderer of :native_or_unimrcp" do
              def expect_playback(filename = audio_filename)
                mock_call.should_receive(:execute_agi_command).ordered.once.with('EXEC Playback', filename).and_return code: 200
              end

              def expect_playback_noanswer
                mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename + ',noanswer').and_return code: 200
              end

              def expect_mrcpsynth(doc = ssml_doc)
                mock_call.should_receive(:execute_agi_command).ordered.once.with('EXEC MRCPSynth', ["\"#{doc.to_s.squish.gsub('"', '\"')}\"", ''].join(',')).and_return code: 200, result: 1
              end

              let(:audio_filename) { 'tt-monkeys' }

              let :ssml_doc do
                RubySpeech::SSML.draw do
                  audio :src => audio_filename do
                    string "Foobar"
                  end
                end
              end

              let(:command_opts) { {} }

              let :command_options do
                { :render_document => {:value => ssml_doc}, renderer: :native_or_unimrcp }.merge(command_opts)
              end

              let :original_command do
                Punchblock::Component::Output.new command_options
              end

              let(:playbackstatus) { 'SUCCESS' }
              before { mock_call.stub(:channel_var).with('PLAYBACKSTATUS').and_return playbackstatus }

              describe 'ssml' do
                context 'unset' do
                  let(:ssml_doc) { nil }
                  it "should return an error and not execute any actions" do
                    subject.execute
                    error = ProtocolError.new.setup 'option error', 'An SSML document is required.'
                    original_command.response(0.1).should be == error
                  end
                end

                context 'with a single audio SSML node' do
                  let(:audio_filename) { 'tt-monkeys' }
                  let :ssml_doc do
                    RubySpeech::SSML.draw language: 'pt-BR' do
                      audio :src => audio_filename do
                        voice name: 'frank' do
                          string "Hello world"
                        end
                      end
                    end
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
                    expect_playback
                    subject.execute
                    original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                  end

                  context "when the audio filename is prefixed by file://" do
                    let(:audio_filename) { 'file://tt-monkeys' }

                    it 'should playback the audio file using Playback' do
                      expect_answered
                      expect_playback 'tt-monkeys'
                      subject.execute
                    end
                  end

                  context "when the audio filename has an extension" do
                    let(:audio_filename) { 'tt-monkeys.wav' }

                    it 'should playback the audio file using Playback' do
                      expect_answered
                      expect_playback 'tt-monkeys'
                      subject.execute
                    end

                    context "when there are other dots in the filename" do
                      let(:audio_filename) { 'blue.tt-monkeys.wav' }

                      it 'should playback the audio file using Playback' do
                        expect_answered
                        expect_playback 'blue.tt-monkeys'
                        subject.execute
                      end
                    end
                  end

                  context "when we get a RubyAMI Error" do
                    it "should send an error complete event" do
                      expect_answered
                      error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                      mock_call.should_receive(:execute_agi_command).and_raise error
                      subject.execute
                      complete_reason = original_command.complete_event(0.1).reason
                      complete_reason.should be_a Punchblock::Event::Complete::Error
                      complete_reason.details.should == "Terminated due to AMI error 'FooBar'"
                    end
                  end

                  context "when the channel is gone" do
                    it "should send an error complete event" do
                      expect_answered
                      error = ChannelGoneError.new 'FooBar'
                      mock_call.should_receive(:execute_agi_command).and_raise error
                      subject.execute
                      complete_reason = original_command.complete_event(0.1).reason
                      complete_reason.should be_a Punchblock::Event::Complete::Hangup
                    end
                  end

                  context "when the PLAYBACKSTATUS variable is set to 'FAILED'" do
                    let(:playbackstatus) { 'FAILED' }

                    let(:synthstatus) { 'SUCCESS' }
                    before { mock_call.stub(:channel_var).with('SYNTHSTATUS').and_return synthstatus }

                    let :fallback_doc do
                      RubySpeech::SSML.draw language: 'pt-BR' do
                        voice name: 'frank' do
                          string "Hello world"
                        end
                      end
                    end

                    it "should attempt to render the children of the audio tag via MRCP and then send a complete event" do
                      expect_answered
                      expect_playback
                      expect_mrcpsynth fallback_doc
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "and the SYNTHSTATUS variable is set to 'ERROR'" do
                      let(:synthstatus) { 'ERROR' }

                      it "should send an error complete event" do
                        expect_answered
                        expect_playback
                        expect_mrcpsynth fallback_doc
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to UniMRCP error"
                      end
                    end
                  end
                end

                context 'with a single text node without spaces' do
                  let(:audio_filename) { 'tt-monkeys' }
                  let :ssml_doc do
                    RubySpeech::SSML.draw { string audio_filename }
                  end

                  it 'should playback the audio file using Playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                  end

                  it 'should send a complete event when the file finishes playback' do
                    expect_answered
                    expect_playback
                    subject.execute
                    original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                  end

                  context "when we get a RubyAMI Error" do
                    it "should send an error complete event" do
                      expect_answered
                      error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                      mock_call.should_receive(:execute_agi_command).and_raise error
                      subject.execute
                      complete_reason = original_command.complete_event(0.1).reason
                      complete_reason.should be_a Punchblock::Event::Complete::Error
                      complete_reason.details.should == "Terminated due to AMI error 'FooBar'"
                    end
                  end

                  context "with early media playback" do
                    it "should play the file with Playback" do
                      expect_answered false
                      expect_playback_noanswer
                      mock_call.should_receive(:send_progress)
                      subject.execute
                    end

                    context "with interrupt_on set to something that is not nil" do
                      let(:audio_filename) { 'tt-monkeys' }
                      let :command_options do
                        {
                          :render_document => {
                            :value => RubySpeech::SSML.draw { string audio_filename },
                          },
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

                context 'with multiple audio SSML nodes' do
                  let(:audio_filename1) { 'foo' }
                  let(:audio_filename2) { 'bar' }
                  let(:audio_filename3) { 'baz' }
                  let :ssml_doc do
                    RubySpeech::SSML.draw do
                      audio :src => audio_filename1 do
                        string "Fallback 1"
                      end
                      audio :src => audio_filename2 do
                        string "Fallback 2"
                      end
                      audio :src => audio_filename3 do
                        string "Fallback 3"
                      end
                    end
                  end

                  it 'should playback all audio files using Playback' do
                    latch = CountDownLatch.new 2
                    expect_playback audio_filename1
                    expect_playback audio_filename2
                    expect_playback audio_filename3
                    expect_answered
                    subject.execute
                    latch.wait 2
                    sleep 2
                  end

                  it 'should send a complete event after the final file has finished playback' do
                    expect_answered
                    expect_playback audio_filename1
                    expect_playback audio_filename2
                    expect_playback audio_filename3
                    latch = CountDownLatch.new 1
                    original_command.should_receive(:add_event).once.with do |e|
                      e.reason.should be_a Punchblock::Component::Output::Complete::Finish
                      latch.countdown!
                    end
                    subject.execute
                    latch.wait(2).should be_true
                  end

                  context "when the PLAYBACKSTATUS variable is set to 'FAILED'" do
                    let(:synthstatus) { 'SUCCESS' }
                    before { mock_call.stub(:channel_var).with('PLAYBACKSTATUS').and_return 'SUCCESS', 'FAILED', 'SUCCESS' }
                    before { mock_call.stub(:channel_var).with('SYNTHSTATUS').and_return synthstatus }

                    let :fallback_doc do
                      RubySpeech::SSML.draw do
                        string "Fallback 2"
                      end
                    end

                    it "should attempt to render the document via MRCP and then send a complete event" do
                      expect_answered
                      expect_playback audio_filename1
                      expect_playback audio_filename2
                      expect_mrcpsynth fallback_doc
                      expect_playback audio_filename3
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "and the SYNTHSTATUS variable is set to 'ERROR'" do
                      let(:synthstatus) { 'ERROR' }

                      it "should terminate playback and send an error complete event" do
                        expect_answered
                        expect_playback audio_filename1
                        expect_playback audio_filename2
                        expect_mrcpsynth fallback_doc
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to UniMRCP error"
                      end
                    end
                  end
                end

                context "with an SSML document containing top-level elements other than <audio/>" do
                  let :ssml_doc do
                    RubySpeech::SSML.draw do
                      string "Foo Bar"
                    end
                  end

                  it "should return an unrenderable document error" do
                    subject.execute
                    error = ProtocolError.new.setup 'unrenderable document error', 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.'
                    original_command.response(0.1).should be == error
                  end
                end

                context 'with multiple documents' do
                  let :second_ssml_doc do
                    RubySpeech::SSML.draw do
                      audio :src => 'two.wav' do
                        string "Bazzz"
                      end
                    end
                  end

                  let :third_ssml_doc do
                    RubySpeech::SSML.draw do
                      audio :src => 'three.wav' do
                        string "Barrrr"
                      end
                    end
                  end

                  let(:command_opts) { { render_documents: [{value: ssml_doc}, {value: second_ssml_doc}, {value: third_ssml_doc}] } }

                  it "should render each document in turn using a Playback per document" do
                    expect_answered
                    expect_playback
                    expect_playback 'two'
                    expect_playback 'three'
                    subject.execute
                    original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                  end

                  context "when the PLAYBACKSTATUS variable is set to 'FAILED'" do
                    let(:synthstatus) { 'SUCCESS' }
                    before { mock_call.stub(:channel_var).with('PLAYBACKSTATUS').and_return 'SUCCESS', 'FAILED', 'SUCCESS' }
                    before { mock_call.stub(:channel_var).with('SYNTHSTATUS').and_return synthstatus }

                    let :fallback_doc do
                      RubySpeech::SSML.draw do
                        string "Bazzz"
                      end
                    end

                    it "should attempt to render the document via MRCP and then send a complete event" do
                      expect_answered
                      expect_playback
                      expect_playback 'two'
                      expect_mrcpsynth fallback_doc
                      expect_playback 'three'
                      subject.execute
                      original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    context "and the SYNTHSTATUS variable is set to 'ERROR'" do
                      let(:synthstatus) { 'ERROR' }

                      it "should terminate playback and send an error complete event" do
                        expect_answered
                        expect_playback
                        expect_playback 'two'
                        expect_mrcpsynth fallback_doc
                        subject.execute
                        complete_reason = original_command.complete_event(0.1).reason
                        complete_reason.should be_a Punchblock::Event::Complete::Error
                        complete_reason.details.should == "Terminated due to UniMRCP error"
                      end
                    end
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
                  RubyAMI::Event.new 'DTMF',
                    'Digit' => digit.to_s,
                    'Start' => position == :start ? 'Yes' : 'No',
                    'End'   => position == :end ? 'Yes' : 'No'
                end

                def send_ami_events_for_dtmf(digit)
                  mock_call.process_ami_event ami_event_for_dtmf(digit, :start)
                  mock_call.process_ami_event ami_event_for_dtmf(digit, :end)
                end

                let(:reason) { original_command.complete_event(5).reason }
                let(:channel) { "SIP/1234-00000000" }
                let :ami_event do
                  RubyAMI::Event.new 'AsyncAGI',
                    'SubEvent'  => "Start",
                    'Channel'   => channel,
                    'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
                end

                context "set to nil" do
                  let(:command_opts) { { :interrupt_on => nil } }
                  it "does not redirect the call" do
                    expect_answered
                    expect_playback
                    mock_call.async.should_receive(:redirect_back).never
                    subject.execute
                    original_command.response(0.1).should be_a Ref
                    send_ami_events_for_dtmf 1
                  end
                end

                context "set to :any" do
                  let(:command_opts) { { :interrupt_on => :any } }

                  before do
                    expect_answered
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename)
                    subject.wrapped_object.should_receive(:send_finish).and_return nil
                  end

                  context "when a DTMF digit is received" do
                    it "sends the correct complete event" do
                      mock_call.async.should_receive :redirect_back
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      original_command.should_not be_complete
                      send_ami_events_for_dtmf 1
                      mock_call.async.process_ami_event ami_event
                      sleep 0.2
                      original_command.should be_complete
                      reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    it "redirects the call back to async AGI" do
                      mock_call.async.should_receive(:redirect_back).once
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
                    mock_call.should_receive(:execute_agi_command).once.with('EXEC Playback', audio_filename)
                    subject.wrapped_object.should_receive(:send_finish).and_return nil
                  end

                  context "when a DTMF digit is received" do
                    it "sends the correct complete event" do
                      mock_call.async.should_receive :redirect_back
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      original_command.should_not be_complete
                      send_ami_events_for_dtmf 1
                      mock_call.async.process_ami_event ami_event
                      sleep 0.2
                      original_command.should be_complete
                      reason.should be_a Punchblock::Component::Output::Complete::Finish
                    end

                    it "redirects the call back to async AGI" do
                      mock_call.async.should_receive(:redirect_back).once
                      subject.execute
                      original_command.response(0.1).should be_a Ref
                      send_ami_events_for_dtmf 1
                    end
                  end
                end

                context "set to :voice" do
                  let(:command_opts) { { :interrupt_on => :voice } }
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
                RubyAMI::Event.new 'AsyncAGI',
                  'SubEvent'  => "Start",
                  'Channel'   => channel,
                  'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before do
                command.request!
                original_command.request!
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
