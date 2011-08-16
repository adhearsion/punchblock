module Punchblock
  class Rayo
    extend ActiveSupport::Autoload

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

    autoload :Audio
    autoload :Command
    autoload :CommandNode
    autoload :Component
    autoload :Connection
    autoload :HasHeaders
    autoload :Header
    autoload :RayoNode

    eager_autoload do
      autoload :Event
      autoload :Ref
    end

    ActiveSupport::Autoload.eager_autoload!

    ##
    # Create a new protocol object with which to communicate with the Rayo server.
    # See Rayo::Connection for details of options
    #
    def initialize(options = {})
      @connection = Connection.new options
    end

    def method_missing(method_name, *args)
      @connection.__send__ method_name, *args
    end
  end
end
