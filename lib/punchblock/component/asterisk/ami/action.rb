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
            [:name] + super
          end

          class Param < RayoNode
            ##
            # @param [String] name
            # @param [String] value
            #
            def self.new(name, value = '')
              super(:param).tap do |new_node|
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
            # @param [Symbol] name the new name for the param
            def name=(name)
              write_attr :name, name.to_s.gsub('_', '-')
            end

            # The Header's value
            # @return [String]
            def value
              read_attr :value
            end

            # Set the Header's value
            # @param [String] value the new value for the param
            def value=(value)
              write_attr :value, value
            end

            def inspect_attributes # :nodoc:
              [:name, :value] + super
            end
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

              def inspect_attributes
                [:message]
              end
            end
          end # Complete
        end # Action
      end # AMI
    end # Asterisk
  end # Component
end # Punchblock
