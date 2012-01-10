require 'punchblock/key_value_pair_node'

module Punchblock
  module Component
    module Asterisk
      module AMI
        class Action < ComponentNode
          register :action, :ami

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
          # @return [Hash] hash of key-value pairs of params
          #
          def params_hash
            params.inject({}) do |hash, param|
              hash[param.name] = param.value
              hash
            end
          end

          ##
          # @return [Array[Param]] params
          #
          def params
            find('//ns:param', :ns => self.class.registered_ns).map do |i|
              Param.new i
            end
          end

          ##
          # @param [Hash, Array] params A hash of key-value param pairs, or an array of Param objects
          #
          def params=(params)
            find('//ns:param', :ns => self.class.registered_ns).each &:remove
            if params.is_a? Hash
              params.each_pair { |k,v| self << Param.new(k, v) }
            elsif params.is_a? Array
              [params].flatten.each { |i| self << Param.new(i) }
            end
          end

          def inspect_attributes # :nodoc:
            [:name, :params] + super
          end

          class Param < RayoNode
            include KeyValuePairNode
          end

          class Complete
            class Success < Event::Complete::Reason
              register :success, :ami_complete

              def self.new(options = {})
                super().tap do |new_node|
                  case options
                  when Nokogiri::XML::Node
                    new_node.inherit options
                  else
                    options.each_pair { |k,v| new_node.send :"#{k}=", v }
                  end
                end
              end

              def message_node
                mn = if self.class.registered_ns
                  find_first 'ns:message', :ns => self.class.registered_ns
                else
                  find_first 'message'
                end

                unless mn
                  self << (mn = RayoNode.new('message', self.document))
                  mn.namespace = self.class.registered_ns
                end
                mn
              end

              def message
                message_node.text
              end

              def message=(other)
                message_node.content = other
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

              def inspect_attributes
                [:message, :attributes_hash]
              end
            end

            class Attribute < RayoNode
              include KeyValuePairNode
            end
          end # Complete
        end # Action
      end # AMI
    end # Asterisk
  end # Component
end # Punchblock
