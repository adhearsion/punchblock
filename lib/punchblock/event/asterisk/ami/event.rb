module Punchblock
  class Event
    module Asterisk
      module AMI
        class Event < Punchblock::Event
          register :event, :ami

          def name
            read_attr :name
          end

          def name=(other)
            write_attr :name, other
          end

          ##
          # @return [Hash] hash of key-value pairs of attributes
          #
          def attributes_hash
            attributes.inject({}) do |hash, attribute|
              hash[attribute.name] = attribute.value
              hash
            end
          end

          ##
          # @return [Array[Attribute]] attributes
          #
          def attributes
            find('//ns:attribute', :ns => self.class.registered_ns).map do |i|
              Attribute.new i
            end
          end

          ##
          # @param [Hash, Array] attributes A hash of key-value attribute pairs, or an array of Attribute objects
          #
          def attributes=(attributes)
            find('//ns:attribute', :ns => self.class.registered_ns).each &:remove
            if attributes.is_a? Hash
              attributes.each_pair { |k,v| self << Attribute.new(k, v) }
            elsif attributes.is_a? Array
              [attributes].flatten.each { |i| self << Attribute.new(i) }
            end
          end

          def inspect_attributes # :nodoc:
            [:name] + super
          end

          class Attribute < RayoNode
            ##
            # @param [String] name
            # @param [String] value
            #
            def self.new(name, value = '')
              super(:attribute).tap do |new_node|
                case name
                when Nokogiri::XML::Node
                  new_node.inherit name
                else
                  new_node.name = name
                  new_node.value = value
                end
                new_node.name = new_node.name.downcase
              end
            end

            # The Header's name
            # @return [Symbol]
            def name
              read_attr(:name).gsub('-', '_').to_sym
            end

            # Set the Header's name
            # @param [Symbol] name the new name for the attribute
            def name=(name)
              write_attr :name, name.to_s.gsub('_', '-')
            end

            # The Header's value
            # @return [String]
            def value
              read_attr :value
            end

            # Set the Header's value
            # @param [String] value the new value for the attribute
            def value=(value)
              write_attr :value, value
            end

            def inspect_attributes # :nodoc:
              [:name, :value] + super
            end
          end
        end
      end
    end
  end # Command
end # Punchblock
