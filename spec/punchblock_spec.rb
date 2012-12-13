require 'spec_helper'

describe Punchblock do
  describe '#client_with_connection' do
    let(:mock_connection) { stub('Connection').as_null_object }

    context 'with :XMPP' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::XMPP.should_receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :XMPP, options
        client.should be_a Punchblock::Client
        client.connection.should be mock_connection
      end
    end

    context 'with :asterisk' do
      it 'sets up an Asterisk connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::Asterisk.should_receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :asterisk, options
        client.should be_a Punchblock::Client
        client.connection.should be mock_connection
      end
    end

    context 'with :freeswitch' do
      it 'sets up an Freeswitch connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::Freeswitch.should_receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :freeswitch, options
        client.should be_a Punchblock::Client
        client.connection.should be mock_connection
      end
    end

    context 'with :yate' do
      it 'raises ArgumentError' do
        options = {:username => 'foo', :password => 'bar'}
        lambda { Punchblock.client_with_connection :yate, options }.should raise_error(ArgumentError)
      end
    end
  end
end
