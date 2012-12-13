# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Connection
    describe Freeswitch do
      let(:media_engine)  { :flite }
      let(:default_voice) { :hal }
      let :options do
        {
          :host           => '127.0.0.1',
          :port           => 8021,
          :password       => 'test',
          :media_engine   => media_engine,
          :default_voice  => default_voice
        }
      end

      let(:mock_event_handler) { stub('Event Handler').as_null_object }

      let(:connection) { described_class.new options }

      let(:mock_stream) { mock 'RubyFS::Stream' }

      subject { connection }

      before do
        subject.event_handler = mock_event_handler
      end

      it 'should set the connection on the translator' do
        subject.translator.connection.should be subject
      end

      it 'should set the media engine on the translator' do
        subject.translator.media_engine.should be media_engine
      end

      it 'should set the default voice on the translator' do
        subject.translator.default_voice.should be default_voice
      end

      describe '#run' do
        it 'starts a RubyFS stream' do
          # subject.should_receive(:new_fs_stream).once.with('127.0.0.1', 8021, 'test').and_return mock_stream
          subject.stream.should_receive(:run).once
          lambda { subject.run }.should raise_error(DisconnectedError)
        end
      end

      describe '#stop' do
        it 'stops the RubyFS::Stream' do
          subject.stream.should_receive(:shutdown).once
          subject.stop
        end

        it 'shuts down the translator' do
          subject.translator.should_receive(:terminate).once
          subject.stop
        end
      end

      it 'sends events from RubyFS to the translator' do
        event = mock 'RubyFS::Event'
        subject.translator.should_receive(:handle_es_event!).once.with event
        subject.stream.fire_event event
      end

      describe '#write' do
        it 'sends a command to the translator' do
          command = mock 'Command'
          options = {:foo => :bar}
          subject.translator.should_receive(:execute_command!).once.with command, options
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
