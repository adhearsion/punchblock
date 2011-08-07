require 'active_support/dependencies/autoload'
require 'active_support/core_ext/object/blank'

module Punchblock
  extend ActiveSupport::Autoload

  autoload :DSL
  autoload :GenericConnection
  autoload :Rayo
  autoload :ProtocolError

  ##
  # This exception may be raised if a transport error is detected.
  TransportError = Class.new StandardError
end
