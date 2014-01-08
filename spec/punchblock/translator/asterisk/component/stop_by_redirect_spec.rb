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
                command.response(0.1).should be_a ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Punchblock::Component::Stop.new }

              before do
                command.request!
              end

              it "sets the command response to true" do
                mock_call.should_receive(:redirect_back)
                mock_call.should_receive(:register_handler).with do |type, *guards|
                  type.should be == :ami
                  guards.should have(2).guards
                  guards[0].should be_a Proc
                  guards[1].should be == {:name => 'AsyncAGI'}
                end

                subject.execute_command command
                command.response(0.1).should be == true
              end

              it "returns an error if the component is already complete" do
                subject.set_complete
                subject.execute_command command
                command.response(0.1).should be_a ProtocolError
              end
            end
          end
        end
      end
    end
  end
end
