module Punchblock
  class Rayo
    class Audio < RayoNode
      ##
      #
      # Creates a new Rayo audio element
      #
      # @param [Hash] options
      # @option options [String] :url of the audio file
      # @option options [String] :text
      #
      def self.new(options = {})
        super(:audio).tap do |new_node|
          case options
          when Nokogiri::XML::Node
            new_node.inherit options
          when Hash
            new_node.src = options[:url] if options[:url]
            new_node << options[:text] if options[:text]
          end
        end
      end

      # The Audio's source
      # @return [String] the url of the audio
      def src
        read_attr :src
      end

      # Set the Audio's source
      # @param [String] src the new source URL for the audio
      def src=(src)
        write_attr :src, src
      end

      # Compare two Audio objects by src
      # @param [Audio] o the Audio object to compare against
      # @return [true, false]
      def eql?(o, *fields)
        super o, *(fields + [:src])
      end

      def inspect_attributes # :nodoc:
        [:src] + super
      end
    end
  end # Rayo
end # Punchblock
