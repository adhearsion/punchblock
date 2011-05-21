module Punchblock

  ##
  # This class represents an active Ozone call
  #
  class Call
    attr_accessor :id

    def initialize(id, to, headers)
      @id = id
      @to = to
      @headers = headers
    end
  end
end
