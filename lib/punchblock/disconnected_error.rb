module Punchblock
  ##
  # This exception may be raised if the connection to the server is interrupted.
  class DisconnectedError < StandardError
  end
end
