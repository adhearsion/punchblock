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
                  item repeat: '2' do
                    ruleref uri: '#digit'
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

                describe "receiving DTMF events" do
                  def ami_event_for_dtmf(digit, position)
                    RubyAMI::Event.new('DTMF').tap do |e|
                      e['Digit']  = digit.to_s
                      e['Start']  = position == :start ? 'Yes' : 'No'
                      e['End']    = position == :end ? 'Yes' : 'No'
                    end
                  end

                  def send_ami_events_for_dtmf(digit)
                    call.process_ami_event ami_event_for_dtmf(digit, :start)
                    call.process_ami_event ami_event_for_dtmf(digit, :end)
                  end

                  let(:reason) { command.complete_event(5).reason }

                  before { subject.execute! }

                  context "when a match is found" do
                    before do
                      send_ami_events_for_dtmf 1
                      send_ami_events_for_dtmf 2
                    end

                    it "should send a success complete event with the relevant data" do
                      reason.should == Punchblock::Component::Input::Complete::Success.new(:mode => :dtmf, :confidence => 1, :utterance => '12', :interpretation => 'dtmf-1 dtmf-2', :component_id => subject.id)
                    end
                  end

                  context "when the match is invalid" do
                    before do
                      send_ami_events_for_dtmf 1
                      send_ami_events_for_dtmf '#'
                    end

                    it "should send a nomatch complete event" do
                      reason.should == Punchblock::Component::Input::Complete::NoMatch.new(:component_id => subject.id)
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
