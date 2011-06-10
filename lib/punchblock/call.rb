module Punchblock

  ##
  # This class represents an active Ozone call
  #
  class Call
    attr_accessor :call_id, :to, :headers

    def initialize(call_id, to, headers)
      @call_id, @to = call_id, to
      # Ensure all our headers have lowercase names and convert to symbols
      @headers = headers.inject({}) do |headers,pair|
        headers[pair.shift.to_s.downcase.to_sym] = pair.shift
        headers
      end
    end

    def to_s
      "#<Punchblock::Call:#{@call_id}>"
    end
  end
end
