##
# DO NOT USE THIS API!
# This file is temporary, to help make testing Punchblock easier.
# THIS IS IMPERMANENT AND WILL DISAPPEAR
module Punchblock
  class DSL
    def initialize(transport, protocol, call, queue) # :nodoc:
      @transport, @protocol, @call, @queue = transport, protocol, call, queue
    end

    def accept # :nodoc:
      write @protocol::Message::Accept.new
    end

    def answer # :nodoc:
      write @protocol::Message::Answer.new
    end

    def hangup # :nodoc:
      write @protocol::Message::Hangup.new
    end

    def reject(reason = :declined) # :nodoc:
      write @protocol::Message::Reject.new reason
    end

    def redirect(dest) # :nodoc:
      write @protocol::Message::Redirect.new(dest)
    end

    def say(string, type = :text) # :nodoc:
      write @protocol::Message::Say.new type => string
      puts "Waiting on the queue..."
      response = @queue.pop
      # TODO: Error handling
    end

    def write(msg) # :nodoc:
      @transport.write @call, msg
    end
  end
end
