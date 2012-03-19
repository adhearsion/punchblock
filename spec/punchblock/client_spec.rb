# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Client do
    let(:connection) { Connection::XMPP.new :username => '1@call.rayo.net', :password => 1 }

    subject { Client.new :connection => connection }

    its(:event_queue)         { should be_a Queue }
    its(:connection)          { should be connection }
    its(:component_registry)  { should be_a Client::ComponentRegistry }

    let(:call_id)         { 'abc123' }
    let(:mock_event)      { stub_everything 'Event' }
    let(:component_id)    { 'abc123' }
    let(:mock_component)  { stub 'Component', :component_id => component_id }
    let(:mock_command)    { stub 'Command' }

    describe '#run' do
      it 'should start up the connection' do
        connection.expects(:run).once
        subject.run
      end
    end

    describe '#stop' do
      it 'should stop the connection' do
        connection.expects(:stop).once
        subject.stop
      end
    end

    it 'should handle connection events' do
      subject.expects(:handle_event).with(mock_event).once
      connection.event_handler.call mock_event
    end

    describe '#handle_event' do
      it "sets the event's client" do
        event = Event::Offer.new
        subject.handle_event event
        event.client.should be subject
      end

      context 'if the event can be associated with a source component' do
        before do
          mock_event.stubs(:source).returns mock_component
          mock_component.expects(:add_event).with mock_event
        end

        it 'should not queue up the event' do
          subject.handle_event mock_event
          subject.event_queue.should be_empty
        end

        it 'should not call event handlers' do
          handler = mock 'handler'
          handler.expects(:call).never
          subject.register_event_handler do |event|
            handler.call event
            throw :halt
          end
          subject.handle_event mock_event
        end
      end

      context 'if the event cannot be associated with a source component' do
        context 'if event handlers have been set' do
          it 'should call the event handler and not queue up the event' do
            handler = mock 'handler'
            handler.expects(:call).once.with mock_event
            subject.register_event_handler do |event|
              handler.call event
              throw :halt
            end
            subject.handle_event mock_event
            subject.event_queue.should be_empty
          end
        end

        context 'if event handlers have not been set' do
          it 'should queue up the event' do
            subject.handle_event mock_event
            subject.event_queue.pop(true).should be == mock_event
          end
        end
      end
    end

    it 'should be able to register and retrieve components' do
      subject.register_component mock_component
      subject.find_component_by_id(component_id).should be mock_component
    end

    describe '#execute_command' do
      let(:component) { Component::Output.new }
      let(:event)     { Event::Complete.new }

      before do
        connection.expects(:write).once.with component, :call_id => call_id
      end

      let :execute_command do
        subject.execute_command component, :call_id => call_id
      end

      it 'should write the command to the connection' do
        execute_command
      end

      it "should set the command's client" do
        execute_command
        component.client.should be subject
      end

      it "should handle a component's events" do
        subject.expects(:trigger_handler).with(:event, event).once
        execute_command
        component.request!
        component.execute!
        component.add_event event
      end
    end
  end # describe Client
end # Punchblock
