# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Freeswitch
      module Component
        describe Output do
          include HasMockCallbackConnection

          let(:translator)  { Punchblock::Translator::Freeswitch.new connection }
          let(:mock_call)   { Punchblock::Translator::Freeswitch::Call.new 'foo', translator }

          let :original_command do
            Punchblock::Component::Output.new command_options
          end

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let :command_options do
            { :render_document => {:value => ssml_doc} }
          end

          subject { Output.new original_command, mock_call }

          describe '#execute' do
            before { original_command.request! }
            def expect_playback(filename = audio_filename)
              subject.wrapped_object.should_receive(:application).once.with 'playback', "file_string://#{filename}"
            end

            let(:audio_filename) { 'http://foo.com/bar.mp3' }

            let :ssml_doc do
              RubySpeech::SSML.draw do
                audio :src => audio_filename
              end
            end

            let(:command_opts) { {} }

            let :command_options do
              { :render_document => {:value => ssml_doc} }.merge(command_opts)
            end

            let :original_command do
              Punchblock::Component::Output.new command_options
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

              context 'with a single audio SSML node' do
                let(:audio_filename) { 'http://foo.com/bar.mp3' }
                let :ssml_doc do
                  RubySpeech::SSML.draw { audio :src => audio_filename }
                end

                it 'should playback the audio file using the playback application' do
                  expect_playback
                  subject.execute
                end

                it 'should send a complete event when the file finishes playback' do
                  expect_playback
                  subject.execute
                  subject.handle_es_event RubyFS::Event.new(nil, :event_name => "CHANNEL_EXECUTE_COMPLETE", :application_response => 'FILE PLAYED')
                  original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
                end

                context "when playback returns an error" do
                  let(:fs_event) { RubyFS::Event.new(nil, :event_name => "CHANNEL_EXECUTE_COMPLETE", :application_response => "PLAYBACK ERROR") }
                  let(:complete_reason) { original_command.complete_event(0.1).reason }

                  it "sends a complete event with an error reason" do
                    expect_playback
                    subject.execute
                    subject.handle_es_event fs_event
                    complete_reason.should be_a Punchblock::Event::Complete::Error
                    complete_reason.details.should == 'Engine error: PLAYBACK ERROR'
                  end
                end
              end

              context 'with multiple audio SSML nodes' do
                let(:audio_filename1) { 'http://foo.com/bar.mp3' }
                let(:audio_filename2) { 'http://foo.com/baz.mp3' }
                let :ssml_doc do
                  RubySpeech::SSML.draw do
                    audio :src => audio_filename1
                    audio :src => audio_filename2
                  end
                end

                it 'should playback all audio files using playback' do
                  expect_playback [audio_filename1, audio_filename2].join('!')
                  subject.execute
                end

                it 'should send a complete event when the files finish playback' do
                  expect_playback([audio_filename1, audio_filename2].join('!'))
                  subject.execute
                  subject.handle_es_event RubyFS::Event.new(nil, :event_name => "CHANNEL_EXECUTE_COMPLETE", :application_response => "FILE PLAYED")
                  original_command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Finish
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
                let(:audio_filename) { 'http://foo.com/bar.mp3' }
                let :ssml_doc do
                  RubySpeech::SSML.draw { audio :src => audio_filename }
                end
                let(:command_opts) { { :render_documents => [{:value => ssml_doc}, {:value => ssml_doc}] } }

                it "should render all audio files from all documents" do
                  expect_playback [audio_filename, audio_filename].join('!')
                  subject.execute
                end
              end
            end

            describe 'start-offset' do
              context 'unset' do
                let(:command_opts) { { :start_offset => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'set' do
                let(:command_opts) { { :start_offset => 10 } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A start_offset value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'start-paused' do
              context 'false' do
                let(:command_opts) { { :start_paused => false } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'true' do
                let(:command_opts) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A start_paused value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'repeat-interval' do
              context 'unset' do
                let(:command_opts) { { :repeat_interval => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'set' do
                let(:command_opts) { { :repeat_interval => 10 } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'repeat-times' do
              context 'unset' do
                let(:command_opts) { { :repeat_times => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'set' do
                let(:command_opts) { { :repeat_times => 2 } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'max-time' do
              context 'unset' do
                let(:command_opts) { { :max_time => nil } }
                it 'should not pass any options to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'set' do
                let(:command_opts) { { :max_time => 30 } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'A max_time value is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end
            end

            describe 'voice' do
              context 'unset' do
                let(:command_opts) { { :voice => nil } }
                it 'should not pass the v option to Playback' do
                  expect_playback
                  subject.execute
                end
              end

              context 'set' do
                let(:command_opts) { { :voice => 'alison' } }
                it "should ignore the voice option" do
                  expect_playback
                  subject.execute
                end
              end
            end

            describe 'interrupt_on' do
              context "set to nil" do
                let(:command_opts) { { :interrupt_on => nil } }
                it "should not pass any digits to Playback" do
                  expect_playback
                  subject.execute
                end
              end

              context "set to :any" do
                let(:command_opts) { { :interrupt_on => :any } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of any is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context "set to :dtmf" do
                let(:command_opts) { { :interrupt_on => :dtmf } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of dtmf is unsupported.'
                  original_command.response(0.1).should be == error
                end
              end

              context "set to :voice" do
                let(:command_opts) { { :interrupt_on => :voice } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = ProtocolError.new.setup 'option error', 'An interrupt-on value of voice is unsupported.'
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

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                subject.wrapped_object.should_receive(:application)
                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "sends the correct complete event" do
                subject.wrapped_object.should_receive(:application)
                original_command.should_not be_complete
                subject.execute_command command
                reason.should be_a Punchblock::Event::Complete::Stop
                original_command.should be_complete
              end

              it "breaks the current dialplan application" do
                subject.wrapped_object.should_receive(:application).once.with 'break'
                subject.execute_command command
              end
            end
          end
        end

      end
    end
  end
end
