require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe Output do
            let(:channel)         { 'SIP/foo' }
            let(:mock_call)       { mock 'Call' }#, :channel => channel }
            let(:command_options) { nil }

            let :command do
              Punchblock::Component::Output.new command_options
            end

            subject { Output.new command, mock_call }

            describe '#execute' do
              before { command.request! }

              it 'should send a ref response immediately' do
                subject.execute
                command.component_id.should == subject.id
              end

              context 'with a media engine of :asterisk' do
                context 'with a single audio SSML node' do
                  let(:audio_filename) { 'http://foo.com/bar.mp3' }
                  let :command_options do
                    filename = audio_filename
                    {
                      :ssml => RubySpeech::SSML.draw { audio :src => filename }
                    }
                  end

                  it 'should playback the audio file using STREAM FILE' do
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename, '"'
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
                    filename1 = audio_filename1
                    filename2 = audio_filename2
                    {
                      :ssml => RubySpeech::SSML.draw do
                        audio :src => filename1
                        audio :src => filename2
                      end
                    }
                  end

                  it 'should playback each audio file using STREAM FILE' do
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename1, '"'
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename2, '"'
                    subject.execute
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
              end
            end
          end
        end
      end
    end
  end
end
