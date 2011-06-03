##
# DO NOT USE THIS API!
# This file is temporary, to help make testing Punchblock easier.
# THIS IS IMPERMANENT AND WILL DISAPPEAR
module Punchblock
  class DSL
    def initialize(connection, call, queue) # :nodoc:
      @connection, @call, @queue = connection, call, queue
    end

    def accept # :nodoc:
      write @connection.class::Accept.new
    end

    def answer # :nodoc:
      write @connection.class::Answer.new
    end

    def hangup # :nodoc:
      write @connection.class::Hangup.new
    end

    def reject(reason = :declined) # :nodoc:
      write @connection.class::Reject.new reason
    end

    def redirect(dest) # :nodoc:
      write @connection.class::Redirect.new(dest)
    end

    def say(string, type = :text) # :nodoc:
      write @connection.class::Say.new type => string
      puts "Waiting on the queue..."
      response = @queue.pop
      # TODO: Error handling
    end

    def write(msg) # :nodoc:
      @connection.write @call, msg
    end
  end
end
