require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe Output do
            let(:media_engine)    { nil }
            let(:translator)      { Punchblock::Translator::Asterisk.new mock('AMI'), mock('Client'), media_engine }
            let(:mock_call)       { mock 'Call', :translator => translator }
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

              context 'with a media engine of :unimrcp' do
                let(:media_engine) { :unimrcp }

                let(:audio_filename) { 'http://foo.com/bar.mp3' }

                let :ssml_doc do
                  filename = audio_filename
                  RubySpeech::SSML.draw do
                    audio :src => filename
                    say_as(:interpret_as => :cardinal) { 'FOO' }
                  end
                end

                let :command_options do
                  { :ssml => ssml_doc }
                end

                it "should execute MRCPSynth" do
                  mock_call.expects(:send_agi_action!).once.with 'EXEC MRCPSynth', ssml_doc.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
                  subject.execute
                end

                it 'should send a complete event when MRCPSynth completes' do
                  def mock_call.send_agi_action!(*args, &block)
                    block.call Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new(:code => 200, :result => 1)
                  end
                  subject.execute
                  command.complete_event(0.1).reason.should be_a Punchblock::Component::Output::Complete::Success
                end

                context "with barge in digits set" do
                  it "should pass the i option for MRCPSynth" do
                    pending
                    mock_call.should_receive(:execute).with('MRCPSynth', 'hello', 'i=any').once.and_return pbx_result_response 0
                    @speech_engines.unimrcp(mock_call, 'hello', :interrupt_digits => 'any')
                  end
                end
              end

              context 'with a media engine of :asterisk' do
                let(:media_engine) { :asterisk }

                context 'with a single audio SSML node' do
                  let(:audio_filename) { 'http://foo.com/bar.mp3' }
                  let :command_options do
                    filename = audio_filename
                    {
                      :ssml => RubySpeech::SSML.draw { audio :src => filename }
                    }
                  end

                  it 'should playback the audio file using STREAM FILE' do
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename, nil do
                      subject.continue!
                      true
                    end
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
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename1, nil do
                      subject.continue!
                      true
                    end
                    mock_call.expects(:send_agi_action!).once.with 'STREAM FILE', audio_filename2, nil do
                      subject.continue!
                      true
                    end
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
