require 'spec_helper'

module Punchblock
  module Translator
    describe Asterisk do
      let(:ami_client) { mock 'RubyAMI::Client' }

      subject { Asterisk.new ami_client }

      its(:ami_client) { should be ami_client }

      describe '#execute_command' do
        describe 'with a call command' do
          let(:command) { Command::Answer.new }
          let(:call_id) { 'abc123' }

          it 'executes the call command' do
            subject.actor_subject.expects(:execute_call_command).with do |c|
              c.should be command
              c.call_id.should == call_id
            end
            subject.execute_command command, :call_id => call_id
          end
        end

        describe 'with a component command' do
          let(:command)       { Component::Stop.new }
          let(:call_id)       { 'abc123' }
          let(:component_id)  { '123abc' }

          it 'executes the component command' do
            subject.actor_subject.expects(:execute_component_command).with do |c|
              c.should be command
              c.call_id.should == call_id
              c.component_id.should == component_id
            end
            subject.execute_command command, :call_id => call_id, :component_id => component_id
          end
        end

        describe 'with a global command' do
          let(:command) { Command::Dial.new }

          it 'executes the command directly' do
            subject.actor_subject.expects(:execute_global_command).with command
            subject.execute_command command
          end
        end
      end

      describe '#execute_call_command' do
        it 'sends the command to the call for execution'
      end

      describe '#execute_component_command' do
        it 'sends the command to the component for execution'
      end

      describe '#execute_global_command' do
        context 'with a Dial' do
          pending
        end
      end
    end
  end
end
