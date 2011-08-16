##
# DO NOT USE THIS API!
# This file is temporary, to help make testing Punchblock easier.
# THIS IS IMPERMANENT AND WILL DISAPPEAR
module Punchblock
  class DSL
    def initialize(protocol, call, queue) # :nodoc:
      @protocol, @call, @queue = protocol, call, queue
    end

    def accept # :nodoc:
      write @protocol.class::Command::Accept.new
    end

    def answer # :nodoc:
      write @protocol.class::Command::Answer.new
    end

    def hangup # :nodoc:
      write @protocol.class::Command::Hangup.new
    end

    def reject(reason = nil) # :nodoc:
      write @protocol.class::Command::Reject.new(:reason => reason)
    end

    def redirect(dest) # :nodoc:
      write @protocol.class::Command::Redirect.new(:to => dest)
    end

    def record(options = {})
      write @protocol.class::Component::Record.new(options)
    end

    def say(string, type = :text) # :nodoc:
      write @protocol.class::Component::Tropo::Say.new(type => string)
      puts "Waiting on the queue..."
      response = @queue.pop
      # TODO: Error handling
    end

    def write(msg) # :nodoc:
      @protocol.write @call, msg
    end
  end
end
