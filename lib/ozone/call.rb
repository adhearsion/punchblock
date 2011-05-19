module Ozone

  ##
  # This class represents an active Ozone call
  #
  class Call
    attr_accessor :from

    def initialize(from, to, params)
      @from    = from
puts params.inspect
      #@headers = params.delete :headers
    end

    # @param [Ozone::Message] Message to send to the call
    def send(msg)
      
    end

  end
end
