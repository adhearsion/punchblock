module Punchblock
  module Protocol
    module Ozone
      class Header < OzoneNode
        def self.new(name, value = '')
          super(:header).tap do |new_node|
            case name
            when Nokogiri::XML::Node
              new_node.inherit name
            else
              new_node.name = name
              new_node.value = value
            end
          end
        end

        # The Header's name
        # @return [Symbol]
        def name
          read_attr(:name).gsub('-', '_').to_sym
        end

        # Set the Header's name
        # @param [Symbol] name the new name for the header
        def name=(name)
          write_attr :name, name.to_s.gsub('_', '-')
        end

        # The Header's value
        # @return [String]
        def value
          read_attr :value
        end

        # Set the Header's value
        # @param [String] value the new value for the header
        def value=(value)
          write_attr :value, value
        end

        # Compare two Header objects by name, and value
        # @param [Header] o the Header object to compare against
        # @return [true, false]
        def eql?(o, *fields)
          super o, *(fields + [:name, :value])
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
