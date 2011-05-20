module Punchblock

  ##
  # This class represents an active Ozone call
  #
  class Call
    attr_accessor :id

    def initialize(id, to, params)
      @id = id
puts params.inspect
      #@headers = params.delete :headers
    end
  end
end
