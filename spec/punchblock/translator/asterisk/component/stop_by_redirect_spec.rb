# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        describe StopByRedirect do

          class MockComponent < Component
            include StopByRedirect
          end

          subject { MockComponent.new Hash.new }

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
                mock_call = mock('Call')
                mock_call.expects(:redirect_back)
                #subject.expects(:call).returns(mock_call)
                subject.execute_command command
                command.response(0.1).should be == true
              end

            end
          end

        end
      end
    end
  end
end
