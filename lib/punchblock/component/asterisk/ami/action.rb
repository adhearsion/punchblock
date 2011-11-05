module Punchblock
  module Component
    module Asterisk
      module AMI
        class Action < ComponentNode
          register :action, :ami

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

          def inspect_params # :nodoc:
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

            def inspect_params # :nodoc:
              [:name, :value] + super
            end
          end

          class Complete
            class Success < Event::Complete::Reason
              register :success, :action_complete

              def inspect_params # :nodoc:
                #[:foo] + super
                super
              end
            end

            class NoMatch < Event::Complete::Reason
              register :nomatch, :action_complete
            end

            class NoAction < Event::Complete::Reason
              register :noaction, :input_complete
            end
          end # Complete
        end # Action
      end # AMI
    end # Asterisk
  end # Component
end # Punchblock
