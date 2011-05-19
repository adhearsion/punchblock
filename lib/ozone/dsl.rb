module Ozone
  class DSL
    def initialize(call, queue)
      @call  = call
      @queue = queue
    end

    def answer
      send Message::Answer.new
    end

    def hangup
      send Message::Hangup.new
    end

    def say(text)
      send Message::Say.new 'Hello world!'
      puts "Waiting on the queue..."
      response = @queue.pop
    end

    def send(msg)
      $connection.command_queue.push [@call, msg]
    end
  end
end
