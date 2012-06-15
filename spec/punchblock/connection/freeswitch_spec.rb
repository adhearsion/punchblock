# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Connection
    describe Freeswitch do
      let :options do
        {
          :host     => '127.0.0.1',
          :port     => 8021,
          :username => 'test',
          :password => 'test'
        }
      end

      let(:mock_event_handler) { stub_everything 'Event Handler' }

      let(:connection) { described_class.new options }

      subject { connection }

      before do
        subject.event_handler = mock_event_handler
      end

      it 'should set the connection on the translator' do
        subject.translator.connection.should be subject
      end

      describe '#run' do
        it 'starts the Librevox listener' do
          pending
          Librevox.expects(:start).once.with(Freeswitch::InboundListener, :event_handler => lambda {})
          lambda { subject.run }.should raise_error DisconnectedError
        end
      end

      describe '#stop' do
        it 'stops the RubyAMI::Client' do
          pending
          subject.ami_client.expects(:stop).once
          subject.stop
        end

        it 'shuts down the translator' do
          subject.translator.expects(:shutdown!).once
          subject.stop
        end
      end

      it 'sends events from Librevox listener to the translator' do
        pending
        event = mock 'Librevox::Response'
        subject.translator.expects(:handle_es_event!).once.with event
        subject.ami_client.handle_event event
      end

      describe '#write' do
        it 'sends a command to the translator' do
          command = mock 'Command'
          options = {:foo => :bar}
          subject.translator.expects(:execute_command!).once.with command, options
          subject.write command, options
        end
      end

      describe 'when a rayo event is received from the translator' do
        it 'should call the event handler with the event' do
          offer = Event::Offer.new
          offer.target_call_id = '9f00061'

          mock_event_handler.expects(:call).once.with offer
          subject.handle_event offer
        end
      end
    end
  end
end
