require 'nokogiri'

module Punchblock
  module Protocol
    module Ozone
      class MessageProxy < Nokogiri::XML::Node
        def self.new(element, document = nil)
          document = Nokogiri::XML::Document.new if document.nil?
          super(element, document)
        end
      end

      class Message
        BASE_OZONE_NAMESPACE    = 'urn:xmpp:ozone'
        OZONE_VERSION           = '1'
        BASE_NAMESPACE_MESSAGES = %w[accept answer hangup reject redirect]

        # Parent object that created this object, if applicable
        attr_accessor :parent, :call_id, :cmd_id

        ##
        # Create a new Ozone Message object.
        #
        # @param [Symbol, Required] Component for this new message
        # @param [Nokogiri::XML::Document, Optional] Existing XML document to which this message should be added
        #
        # @return [Ozone::Message] New Ozone Message object
        def initialize(name, options = {})
          element = options.has_key?(:command) ? options.delete(:command) : name
          @xml = MessageProxy.new(element).tap do |obj|
            scope = BASE_NAMESPACE_MESSAGES.include?(name) ? nil : name
            if scope == 'dial'
              obj.set_attribute 'xmlns', [BASE_OZONE_NAMESPACE, OZONE_VERSION].compact.join(':')
            else
              obj.set_attribute 'xmlns', [BASE_OZONE_NAMESPACE, scope, OZONE_VERSION].compact.join(':')
            end
            # FIXME: Do I need a handle to the parent object?

          end
          @parent  = options.delete :parent
          @call_id = options.delete :call_id
          @cmd_id  = options.delete :cmd_id
        end

        def to_s
          @xml.to_xml
        end
        alias :to_xml :to_s

        # @param [String] Call ID
        # @param [String] Ozone Command ID.  Can be nil
        # @param [String] XML to be converted to an Ozone Message
        def self.parse(call_id, cmd_id, xml)
          # Try to ensure that newlines don't get read as content by Nokogiri
          xml = Nokogiri.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).children

          # TODO: Handle more than one message at a time?
          msg = xml.first
          case msg.name
          when 'offer'
            # Collect headers into an array
            headers = msg.children.inject({}) do |headers, header|
              headers[header['name'].gsub('-','_')] = header['value']
              headers
            end
            call = Punchblock::Call.new call_id, msg['to'], headers
            # TODO: Acknowledge the offer?
            return call
          when 'complete'
            return Complete.parse xml, :call_id => call_id, :cmd_id => cmd_id
          when 'info'
            return Info.parse xml, :call_id => call_id, :cmd_id => cmd_id
          when 'end'
            return End.parse xml, :call_id => call_id, :cmd_id => cmd_id # unless msg.first && msg.first.name == 'error'
          end
        end
      end

    end
  end
end

Dir[File.dirname(__FILE__) + '/ozone/*.rb'].each { |file| require file }
