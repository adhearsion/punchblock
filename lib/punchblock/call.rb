module Punchblock

  ##
  # This class represents an active Ozone call
  #
  class Call
    attr_accessor :id, :to, :headers

    def initialize(id, to, headers)
      @id, @to = id, to
      # Ensure all our headers have lowercase names and convert to symbols
      @headers = headers.inject({}) do |headers,pair|
        headers[pair.shift.downcase.to_sym] = pair.shift
        headers
      end
    end

    def to_s
      "#<Punchblock::Call:#{@id}>"
    end
  end
end
