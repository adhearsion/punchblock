# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Connection
    describe Asterisk do
      let :options do
        {
          :host     => '127.0.0.1',
          :port     => 5038,
          :username => 'test',
          :password => 'test'
        }
      end

      let(:mock_event_handler) { double('Event Handler').as_null_object }

      let(:connection) { Asterisk.new options }

      subject { connection }

      before do
        subject.event_handler = mock_event_handler
      end

      its(:ami_client) { should be_a RubyAMIStreamProxy }
      its('ami_client.stream') { should be_a RubyAMI::Stream }

      it 'should set the connection on the translator' do
        subject.translator.connection.should be subject
      end

      describe '#run' do
        it 'starts the RubyAMI::Stream' do
          subject.ami_client.async.should_receive(:run).once do
            subject.ami_client.terminate
          end
          lambda { subject.run }.should raise_error DisconnectedError
        end

        it 'rebuilds the RubyAMI::Stream if dead' do
          subject.ami_client.async.should_receive(:run).once do
            subject.ami_client.terminate
          end
          lambda { subject.run }.should raise_error DisconnectedError
          subject.ami_client.alive?.should be_false
          subject.should_receive(:new_ami_stream).once do
            subject.ami_client.alive?.should be_true
            subject.ami_client.async.should_receive(:run).once
          end
          lambda { subject.run }.should_not raise_error DisconnectedError
        end
      end

      describe '#stop' do
        it 'stops the RubyAMI::Stream' do
          subject.ami_client.should_receive(:terminate).once
          subject.stop
        end

        it 'shuts down the translator' do
          subject.translator.should_receive(:terminate).once
          subject.stop
        end
      end

      it 'sends events from RubyAMI to the translator' do
        event = RubyAMI::Event.new 'FullyBooted'
        subject.translator.async.should_receive(:handle_ami_event).once.with event
        subject.translator.async.should_receive(:handle_ami_event).once.with RubyAMI::Stream::Disconnected.new
        subject.ami_client.message_received event
      end

      describe '#write' do
        it 'sends a command to the translator' do
          command = double 'Command'
          options = {:foo => :bar}
          subject.translator.async.should_receive(:execute_command).once.with command, options
          subject.write command, options
        end
      end

      describe 'when a rayo event is received from the translator' do
        it 'should call the event handler with the event' do
          offer = Event::Offer.new
          offer.target_call_id = '9f00061'

          mock_event_handler.should_receive(:call).once.with offer
          subject.handle_event offer
        end
      end
    end
  end
end
