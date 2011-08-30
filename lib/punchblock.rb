require 'active_support/dependencies/autoload'
require 'active_support/core_ext/object/blank'
require 'future-resource'

module Punchblock
  extend ActiveSupport::Autoload

  autoload :Command
  autoload :CommandNode
  autoload :Component
  autoload :Connection
  autoload :DSL
  autoload :GenericConnection
  autoload :HasHeaders
  autoload :Header
  autoload :MediaContainer
  autoload :ProtocolError
  autoload :RayoNode

  ##
  # This exception may be raised if a transport error is detected.
  TransportError = Class.new StandardError

  BASE_RAYO_NAMESPACE   = 'urn:xmpp:rayo'
  BASE_TROPO_NAMESPACE  = 'urn:xmpp:tropo'
  RAYO_VERSION          = '1'
  RAYO_NAMESPACES       = {:core => [BASE_RAYO_NAMESPACE, RAYO_VERSION].compact.join(':')}

  [:ext, :record, :output, :input].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_RAYO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_RAYO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end

  [:ask, :conference, :say, :transfer].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_TROPO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_TROPO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end
end

require 'punchblock/event'
require 'punchblock/ref'
