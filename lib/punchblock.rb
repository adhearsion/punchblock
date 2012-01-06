%w{
  active_support/dependencies/autoload
  active_support/core_ext/object/blank
  active_support/core_ext/module/delegation
  future-resource
  has_guarded_handlers
  ruby_speech
  punchblock/core_ext/ruby
}.each { |l| require l }

module Punchblock
  extend ActiveSupport::Autoload

  autoload :Client
  autoload :Command
  autoload :CommandNode
  autoload :Component
  autoload :Connection
  autoload :DisconnectedError
  autoload :HasHeaders
  autoload :Header
  autoload :MediaContainer
  autoload :MediaNode
  autoload :ProtocolError
  autoload :RayoNode
  autoload :Translator

  class << self
    def logger
      @logger || reset_logger
    end

    def logger=(other)
      @logger = other
    end

    def reset_logger
      @logger = NullObject.new
    end
  end

  ##
  # This exception may be raised if a transport error is detected.
  TransportError = Class.new StandardError

  BASE_RAYO_NAMESPACE     = 'urn:xmpp:rayo'
  BASE_TROPO_NAMESPACE    = 'urn:xmpp:tropo'
  BASE_ASTERISK_NAMESPACE = 'urn:xmpp:rayo:asterisk'
  RAYO_VERSION            = '1'
  RAYO_NAMESPACES         = {:core => [BASE_RAYO_NAMESPACE, RAYO_VERSION].compact.join(':')}

  [:ext, :record, :output, :input].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_RAYO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_RAYO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end

  [:conference].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_TROPO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_TROPO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end

  [:agi, :ami].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_ASTERISK_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_ASTERISK_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end
end

require 'punchblock/event'
require 'punchblock/ref'
