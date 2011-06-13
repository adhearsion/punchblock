module Punchblock
  module Protocol
    extend ActiveSupport::Autoload

    autoload :GenericConnection
    autoload :Ozone
    autoload :ProtocolError
  end
end
