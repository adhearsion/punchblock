##
# DO NOT USE THIS API!
# This file is temporary, to help make testing Punchblock easier.
# THIS IS IMPERMANENT AND WILL DISAPPEAR
module Punchblock
  class DSL
    def initialize(transport, protocol, call, queue) # :nodoc:
      @transport = transport
      @protocol  = protocol
      @call      = call
      @queue     = queue
    end

    def answer # :nodoc:
      send @protocol::Message::Answer.new
    end

    def hangup # :nodoc:
      send @protocol::Message::Hangup.new
    end

    def say(string, type = :text) # :nodoc:
      send @protocol::Message::Say.new type => string
      puts "Waiting on the queue..."
      response = @queue.pop
    end

    def send(msg) # :nodoc:
      @transport.send @call, msg
    end
  end
end
