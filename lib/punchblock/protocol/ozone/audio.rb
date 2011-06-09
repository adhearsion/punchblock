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
              new_node.src = src[:url]
            else
              new_node << src if src
            end
          end
        end

        # The Audio's source
        # @return [String]
        def src
          self[:src]
        end

        # Set the Audio's source
        # @param [String] src the new source URL for the audio
        def src=(src)
          self[:src] = src
        end

        # Compare two Audio objects by src
        # @param [Audio] o the Audio object to compare against
        # @return [true, false]
        def eql?(o, *fields)
          super o, *(fields + [:src])
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
