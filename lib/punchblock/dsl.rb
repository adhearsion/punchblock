##
# DO NOT USE THIS API!
# This file is temporary, to help make testing Punchblock easier.
# THIS IS IMPERMANENT AND WILL DISAPPEAR
module Punchblock
  class DSL
    def initialize(connection, protocol, call, queue) # :nodoc:
      @connection, @protocol, @call, @queue = connection, protocol, call, queue
    end

    def accept # :nodoc:
      write @protocol::Accept.new :type => :set
    end

    def answer # :nodoc:
      write @protocol::Answer.new :type => :set
    end

    def hangup # :nodoc:
      write @protocol::Hangup.new :type => :set
    end

    def reject(reason = :declined) # :nodoc:
      write @protocol::Reject.new(reason, :type => :set)
    end

    def redirect(dest) # :nodoc:
      write @protocol::Redirect.new(dest, :type => :set)
    end

    def say(string, type = :text) # :nodoc:
      write @protocol::Say.new type => string, :type => :set
      puts "Waiting on the queue..."
      response = @queue.pop
      # TODO: Error handling
    end

    def write(msg) # :nodoc:
      @connection.write @call, msg
    end
  end
end
