# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe StopByRedirect do

          class MockComponent < Component
            include StopByRedirect
            def set_complete
              @complete = true
            end
          end

          let(:connection)  { double 'Connection' }
          let(:ami_client)  { double('AMI Client').as_null_object }
          let(:translator)  { Punchblock::Translator::Asterisk.new ami_client, connection }
          let(:mock_call)   { Call.new 'SIP/foo', translator, ami_client, connection }

          subject { MockComponent.new Hash.new, mock_call }

          describe "#execute_command" do
            context "with a command it does not understand" do
              let(:command) { Punchblock::Component::Output::Pause.new }

              before { command.request! }
              it "returns a ProtocolError response" do
                subject.execute_command command
                expect(command.response(0.1)).to be_a ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Punchblock::Component::Stop.new }

              before do
                command.request!
              end

              it "sets the command response to true" do
                expect(mock_call).to receive(:redirect_back)
                expect(mock_call).to receive(:register_handler).with { |type, *guards|
                  expect(type).to eq(:ami)
                  expect(guards.size).to eq(1)
                  expect(guards[0]).to be_a Array
                  expect(guards[0][0]).to eq({:name => 'AsyncAGI', [:[], 'SubEvent']=>'Start'})
                  expect(guards[0][1]).to eq({:name => 'AsyncAGIExec'})
                }

                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
              end

              it "returns an error if the component is already complete" do
                subject.set_complete
                subject.execute_command command
                expect(command.response(0.1)).to be_a ProtocolError
              end
            end
          end
        end
      end
    end
  end
end
