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

      let(:mock_event_handler) { stub_everything 'Event Handler' }

      let(:connection) { Asterisk.new options }

      subject { connection }

      before do
        subject.event_handler = mock_event_handler
      end

      its(:ami_client) { should be_a RubyAMI::Client }

      after { connection.translator.terminate }

      it 'should set the connection on the translator' do
        subject.translator.connection.should be subject
      end

      describe '#run' do
        it 'starts the RubyAMI::Client' do
          subject.ami_client.expects(:start).once
          subject.run
        end
      end

      describe '#stop' do
        it 'stops the RubyAMI::Client' do
          subject.ami_client.expects(:stop).once
          subject.stop
        end

        it 'shuts down the translator' do
          subject.translator.expects(:shutdown!).once
          subject.stop
        end
      end

      it 'sends events from RubyAMI to the translator' do
        event = mock 'RubyAMI::Event'
        subject.translator.expects(:handle_ami_event!).once.with event
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
          offer.call_id = '9f00061'

          mock_event_handler.expects(:call).once.with offer
          subject.handle_event offer
        end
      end
    end
  end
end
