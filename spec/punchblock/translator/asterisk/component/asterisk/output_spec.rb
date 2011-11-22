require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe Output do
            let(:channel)       { 'SIP/foo' }
            let(:mock_call)     { mock 'Call' }#, :channel => channel }

            let :command do
              Punchblock::Component::Output.new command_options
            end

            subject { Output.new command, mock_call }

            context 'with a media engine of :asterisk' do
              context 'with a single audio SSML node' do
                let(:audio_filename) { 'http://foo.com/bar.mp3' }
                let :command_options do
                  filename = audio_filename
                  {
                    :ssml => RubySpeech::SSML.draw { audio :src => filename }.to_s
                  }
                end

                it 'should playback the audio file using STREAM FILE' do
                  mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename, '"'
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
