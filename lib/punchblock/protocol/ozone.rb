module Punchblock
  module Protocol
    class Ozone
      extend ActiveSupport::Autoload

      BASE_OZONE_NAMESPACE  = 'urn:xmpp:ozone'
      OZONE_VERSION         = '1'
      OZONE_NAMESPACES      = {:core => [BASE_OZONE_NAMESPACE, OZONE_VERSION].compact.join(':')}

      [:ext, :transfer, :say, :ask, :conference].each do |ns|
        OZONE_NAMESPACES[ns] = [BASE_OZONE_NAMESPACE, ns.to_s, OZONE_VERSION].compact.join(':')
        OZONE_NAMESPACES[:"#{ns}_complete"] = [BASE_OZONE_NAMESPACE, ns.to_s, 'complete', OZONE_VERSION].compact.join(':')
      end

      autoload :Audio
      autoload :Command
      autoload :Connection
      autoload :Event
      autoload :HasHeaders
      autoload :Header
      autoload :OzoneNode
      autoload :Ref

      [Ref] # FIXME: Force autoload Ref so it gets registered properly

      ##
      # Create a new protocol object with which to communicate with the Ozone server.
      # See Ozone::Connection for details of options
      #
      def initialize(options = {})
        @connection = Connection.new options
      end

      def method_missing(method_name, *args)
        @connection.__send__ method_name, *args
      end
    end
  end
end
