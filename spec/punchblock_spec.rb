require 'spec_helper'

describe Punchblock do
  describe '#client_with_connection' do
    let(:mock_connection) { double('Connection').as_null_object }

    context 'with :xmpp' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Punchblock::Connection::XMPP).to receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :xmpp, options
        expect(client).to be_a Punchblock::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :XMPP' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Punchblock::Connection::XMPP).to receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :XMPP, options
        expect(client).to be_a Punchblock::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :asterisk' do
      it 'sets up an Asterisk connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Punchblock::Connection::Asterisk).to receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :asterisk, options
        expect(client).to be_a Punchblock::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :freeswitch' do
      it 'sets up an Freeswitch connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Punchblock::Connection::Freeswitch).to receive(:new).once.with(options).and_return mock_connection
        client = Punchblock.client_with_connection :freeswitch, options
        expect(client).to be_a Punchblock::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :yate' do
      it 'raises ArgumentError' do
        options = {:username => 'foo', :password => 'bar'}
        expect { Punchblock.client_with_connection :yate, options }.to raise_error(ArgumentError)
      end
    end
  end
end
