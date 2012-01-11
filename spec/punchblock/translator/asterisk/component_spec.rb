require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Component do

      end

      module Component
        describe Component do
          let(:translator)  { Punchblock::Translator::Asterisk.new mock('AMI'), mock('Client') }
          let(:call)        { Punchblock::Translator::Asterisk::Call.new 'foo', translator }
          let(:command)     { Punchblock::Component::Input.new }

          subject { Component.new command, call }

          before { command.request! }

          describe "#send_complete_event" do
            before { command.execute! }

            let(:reason) { Punchblock::Event::Complete::Stop.new }
            let :expected_event do
              Punchblock::Event::Complete.new.tap do |c|
                c.reason        = Punchblock::Event::Complete::Stop.new
                c.call_id       = call.id
                c.component_id  = subject.id
              end
            end

            it "should send a complete event with the specified reason" do
              expected_event
              subject.send_complete_event reason
              command.complete_event(0.5).should == expected_event
            end

            it "should cause the actor to be shut down" do
              subject.send_complete_event reason
              subject.should_not be_alive
            end
          end
        end
      end
    end
  end
end
