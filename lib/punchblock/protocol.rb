module Punchblock
  module Protocol
    extend ActiveSupport::Autoload

    autoload :GenericConnection
    autoload :Rayo
    autoload :ProtocolError
  end
end
