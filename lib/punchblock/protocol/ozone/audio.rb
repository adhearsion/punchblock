module Punchblock
  module Protocol
    module Ozone
      class Audio < OzoneNode
        def self.new(src)
          super(:audio).tap do |new_node|
            case src
            when Nokogiri::XML::Node
              new_node.inherit src
            when Hash
              new_node.src = src[:url] if src[:url]
              new_node << src[:text] if src[:text]
            end
          end
        end

        # The Audio's source
        # @return [String]
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

        def attributes
          [:src] + super
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
