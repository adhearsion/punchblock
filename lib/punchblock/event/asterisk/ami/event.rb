# encoding: utf-8

require 'punchblock/key_value_pair_node'

module Punchblock
  class Event
    module Asterisk
      module AMI
        class Event < Punchblock::Event
          register :event, :ami

          def self.new(options = {})
            super().tap do |new_node|
              options.each_pair { |k,v| new_node.send :"#{k}=", v }
            end
          end

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
              hash[attribute.name.downcase.gsub('-', '_').to_sym] = attribute.value
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
            find('//ns:attribute', :ns => self.class.registered_ns).each(&:remove)
            if attributes.is_a? Hash
              attributes.each_pair { |k,v| self << Attribute.new(k, v) }
            elsif attributes.is_a? Array
              [attributes].flatten.each { |i| self << Attribute.new(i) }
            end
          end

          def inspect_attributes # :nodoc:
            [:name, :attributes_hash] + super
          end

          class Attribute < RayoNode
            include KeyValuePairNode
          end
        end
      end
    end
  end # Command
end # Punchblock
