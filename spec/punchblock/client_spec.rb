# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Client do
    let(:connection) { Connection::XMPP.new :username => '1@call.rayo.net', :password => 1 }

    subject { Client.new :connection => connection }

    its(:connection)          { should be connection }
    its(:component_registry)  { should be_a Client::ComponentRegistry }

    let(:call_id)         { 'abc123' }
    let(:mock_event)      { double('Event').as_null_object }
    let(:component_id)    { 'abc123' }
    let(:mock_component)  { double 'Component', :component_id => component_id }
    let(:mock_command)    { double 'Command' }

    describe '#run' do
      it 'should start up the connection' do
        connection.should_receive(:run).once
        subject.run
      end
    end

    describe '#stop' do
      it 'should stop the connection' do
        connection.should_receive(:stop).once
        subject.stop
      end
    end

    it 'should handle connection events' do
      subject.should_receive(:handle_event).with(mock_event).once
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
          mock_event.stub :source => mock_component
          mock_component.should_receive(:add_event).with mock_event
        end

        it 'should not call event handlers' do
          handler = double 'handler'
          handler.should_receive(:call).never
          subject.register_event_handler do |event|
            handler.call event
          end
          subject.handle_event mock_event
        end
      end

      context 'if the event cannot be associated with a source component' do
        before do
          mock_event.stub :source => nil
        end

        it 'should call registered event handlers' do
          handler = double 'handler'
          handler.should_receive(:call).once.with mock_event
          subject.register_event_handler do |event|
            handler.call event
          end
          subject.handle_event mock_event
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
        connection.should_receive(:write).once.with component, :call_id => call_id
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
        subject.should_receive(:trigger_handler).with(:event, event).once
        execute_command
        component.request!
        component.execute!
        component.add_event event
      end
    end
  end # describe Client
end # Punchblock
