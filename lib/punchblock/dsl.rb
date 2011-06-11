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
      write @protocol::Command::Accept.new
    end

    def answer # :nodoc:
      write @protocol::Command::Answer.new
    end

    def hangup # :nodoc:
      write @protocol::Command::Hangup.new
    end

    def reject(reason = nil) # :nodoc:
      write @protocol::Command::Reject.new(:reason => reason)
    end

    def redirect(dest) # :nodoc:
      write @protocol::Command::Redirect.new(:to => dest)
    end

    def say(string, type = :text) # :nodoc:
      write @protocol::Command::Say.new(type => string)
      puts "Waiting on the queue..."
      response = @queue.pop
      # TODO: Error handling
    end

    def write(msg) # :nodoc:
      @connection.write @call, msg
    end
  end
end
