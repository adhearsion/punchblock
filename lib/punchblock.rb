# encoding: utf-8

%w{
  active_support/dependencies/autoload
  active_support/core_ext/object/blank
  active_support/core_ext/module/delegation
  active_support/inflector
  future-resource
  has_guarded_handlers
  ruby_speech
  punchblock/core_ext/ruby
}.each { |l| require l }

module Punchblock
  extend ActiveSupport::Autoload

  autoload :ActorHasGuardedHandlers
  autoload :Client
  autoload :Command
  autoload :CommandNode
  autoload :Component
  autoload :Connection
  autoload :DeadActorSafety
  autoload :DisconnectedError
  autoload :HasHeaders
  autoload :MediaNode
  autoload :ProtocolError
  autoload :RayoNode
  autoload :Translator
  autoload :URIList

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

    #
    # Get a new Punchblock client with a connection attached
    #
    # @param [Symbol] type the connection type (eg :XMPP, :asterisk, :freeswitch)
    # @param [Hash] options the options to pass to the connection (credentials, etc
    #
    # @return [Punchblock::Client] a punchblock client object
    #
    def client_with_connection(type, options)
      connection = Connection.const_get(type == :xmpp ? 'XMPP' : type.to_s.classify).new options
      Client.new :connection => connection
    rescue NameError
      raise ArgumentError, "Connection type #{type.inspect} is not valid."
    end

    def new_uuid
      SecureRandom.uuid
    end

    def jruby?
      @jruby ||= !!(RUBY_PLATFORM =~ /java/)
    end
  end

  ##
  # This exception may be raised if a transport error is detected.
  Error = Class.new StandardError

  BASE_RAYO_NAMESPACE     = 'urn:xmpp:rayo'
  BASE_ASTERISK_NAMESPACE = 'urn:xmpp:rayo:asterisk'
  RAYO_VERSION            = '1'
  RAYO_NAMESPACES         = {:core => [BASE_RAYO_NAMESPACE, RAYO_VERSION].compact.join(':')}

  [:ext, :record, :output, :input, :prompt].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_RAYO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_RAYO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end

  [:agi, :ami].each do |ns|
    RAYO_NAMESPACES[ns] = [BASE_ASTERISK_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
    RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_ASTERISK_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
  end
end

require 'punchblock/event'
require 'punchblock/ref'
