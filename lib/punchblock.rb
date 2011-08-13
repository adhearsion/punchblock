require 'active_support/dependencies/autoload'
require 'active_support/core_ext/object/blank'

module Punchblock
  extend ActiveSupport::Autoload

  autoload :DSL
  autoload :GenericConnection
  autoload :ProtocolError

  eager_autoload do
    autoload :Rayo
  end

  ActiveSupport::Autoload.eager_autoload!

  ##
  # This exception may be raised if a transport error is detected.
  TransportError = Class.new StandardError
end
