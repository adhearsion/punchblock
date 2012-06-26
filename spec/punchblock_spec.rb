require 'spec_helper'

describe Punchblock do
  describe '#client_with_connection' do
    context 'with :XMPP' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        mock_connection = stub_everything 'Connection'
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::XMPP.expects(:new).once.with(options).returns mock_connection
        client = Punchblock.client_with_connection :XMPP, options
        client.should be_a Punchblock::Client
        client.connection.should be mock_connection
      end
    end

    context 'with :asterisk' do
      it 'sets up an Asterisk connection, passing options, and a client with the connection attached' do
        mock_connection = stub_everything 'Connection'
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::Asterisk.expects(:new).once.with(options).returns mock_connection
        client = Punchblock.client_with_connection :asterisk, options
        client.should be_a Punchblock::Client
        client.connection.should be mock_connection
      end
    end

    context 'with :freeswitch' do
      it 'sets up an Freeswitch connection, passing options, and a client with the connection attached' do
        mock_connection = stub_everything 'Connection'
        options = {:username => 'foo', :password => 'bar'}
        Punchblock::Connection::Freeswitch.expects(:new).once.with(options).returns mock_connection
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
