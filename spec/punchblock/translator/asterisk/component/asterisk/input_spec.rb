require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe Input do
            let(:media_engine)    { nil }
            let(:translator)      { Punchblock::Translator::Asterisk.new mock('AMI'), mock('Client'), media_engine }
            let(:call)            { Punchblock::Translator::Asterisk::Call.new 'foo', translator }
            let(:command_options) { nil }

            let :command do
              Punchblock::Component::Input.new command_options
            end

            let :grammar do
              RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'pin' do
                rule id: 'digit' do
                  one_of do
                    0.upto(9) { |d| item { d.to_s } }
                  end
                end

                rule id: 'pin', scope: 'public' do
                  one_of do
                    item do
                      item repeat: '2' do
                        ruleref uri: '#digit'
                      end
                      "#"
                    end
                  end
                end
              end
            end

            let :command_options do
              {

              }
            end

            subject { Input.new command, call }

            describe '#execute' do
              before { command.request! }

              context 'with a media engine of :unimrcp' do
                pending
                let(:media_engine) { :unimrcp }
              end

              context 'with a media engine of :asterisk' do
                let(:media_engine) { :asterisk }

                let(:command_opts) { {} }

                let :command_options do
                  { :mode => :dtmf, :grammar => { :value => grammar } }.merge(command_opts)
                end

                it "should create a matcher from the parsed grammar" do
                  subject.execute
                  subject.matcher.should be_a Input::DTMFMatcher
                  subject.matcher.grammar.should == grammar
                end

                it "should begin capturing DTMF events for the call and pass them to the matcher" do
                  matcher = Input::DTMFMatcher.new grammar
                  Input::DTMFMatcher.expects(:new).returns matcher

                  dtmf = sequence 'dtmf'

                  matcher.expects(:<<).once.with('3').in_sequence dtmf
                  matcher.expects(:match?).once.returns(nil).in_sequence dtmf
                  matcher.expects(:<<).once.with('7').in_sequence dtmf
                  matcher.expects(:match?).once.returns(nil).in_sequence dtmf
                  matcher.expects(:<<).once.with('#').in_sequence dtmf
                  matcher.expects(:match?).once.returns(true).in_sequence dtmf

                  subject.execute!

                  def ami_event_for_dtmf(digit, position)
                    RubyAMI::Event.new('DTMF').tap do |e|
                      e['Digit'] = digit
                      e['Start'] = position == :start ? 'Yes' : 'No'
                      e['End'] = position == :end ? 'Yes' : 'No'
                    end
                  end

                  call.process_ami_event! ami_event_for_dtmf(3, :start)
                  call.process_ami_event! ami_event_for_dtmf(3, :end)
                  call.process_ami_event! ami_event_for_dtmf(7, :start)
                  call.process_ami_event! ami_event_for_dtmf(7, :end)
                  call.process_ami_event! ami_event_for_dtmf('#', :start)
                  call.process_ami_event! ami_event_for_dtmf('#', :end)

                  command.complete_event(0.1)
                end

                describe "receiving DTMF events" do
                  describe "checked against the matcher" do
                    context "when a match is found" do
                      it "should send a success complete event with the relevant data"
                    end

                    context "when the match is invalid" do
                      it "should send a nomatch complete event"
                    end
                  end
                end

                describe 'grammar' do
                  context 'unset' do
                    let(:command_opts) { { :grammar => nil } }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new 'option error', 'A grammar document is required.'
                      command.response(0.1).should == error
                    end
                  end
                end

                describe 'mode' do
                  context 'dtmf' do
                    let(:command_opts) { { :mode => :dtmf } }
                    it ""
                  end

                  context 'unset' do
                    let(:command_opts) { { :mode => nil } }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                      command.response(0.1).should == error
                    end
                  end

                  context 'any' do
                    let(:command_opts) { { :mode => :any } }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                      command.response(0.1).should == error
                    end
                  end

                  context 'speech' do
                    let(:command_opts) { { :mode => :speech } }
                    it "should return an error and not execute any actions" do
                      subject.execute
                      error = ProtocolError.new 'option error', 'A mode value other than DTMF is unsupported on Asterisk.'
                      command.response(0.1).should == error
                    end
                  end
                end

                describe 'terminator' do
                  pending
                end

                describe 'recognizer' do
                  pending
                end

                describe 'initial-timeout' do
                  pending
                end

                describe 'inter-digit-timeout' do
                  pending
                end

                describe 'sensitivity' do
                  pending
                end

                describe 'min-confidence' do
                  pending
                end

                describe 'max-silence' do
                  pending
                end
              end
            end
          end
        end
      end
    end
  end
end
