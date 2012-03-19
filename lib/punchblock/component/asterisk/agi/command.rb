# encoding: utf-8

module Punchblock
  module Component
    module Asterisk
      module AGI
        class Command < ComponentNode
          register :command, :agi

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
          # @return [Array[String]] array of values of params
          #
          def params_array
            params.map(&:value)
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
            find('//ns:param', :ns => self.class.registered_ns).each(&:remove)
            [params].flatten.each { |i| self << Param.new(i) } if params.is_a? Array
          end

          def inspect_attributes # :nodoc:
            [:name, :params_array] + super
          end

          class Param < RayoNode
            ##
            # @param [String] name
            # @param [String] value
            #
            def self.new(value)
              super(:param).tap do |new_node|
                case value
                when Nokogiri::XML::Node
                  new_node.inherit value
                else
                  new_node.value = value
                end
              end
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
              [:value] + super
            end
          end

          class Complete
            class Success < Event::Complete::Reason
              register :success, :agi_complete

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

              def node_with_name(name)
                n = if self.class.registered_ns
                  find_first "ns:#{name}", :ns => self.class.registered_ns
                else
                  find_first name
                end

                unless n
                  self << (n = RayoNode.new(name, self.document))
                  n.namespace = self.class.registered_ns
                end
                n
              end

              def code_node
                node_with_name 'code'
              end

              def result_node
                node_with_name 'result'
              end

              def data_node
                node_with_name 'data'
              end

              def code
                code_node.text.to_i
              end

              def code=(other)
                code_node.content = other
              end

              def result
                result_node.text.to_i
              end

              def result=(other)
                result_node.content = other
              end

              def data
                data_node.text
              end

              def data=(other)
                data_node.content = other
              end

              def inspect_attributes
                [:code, :result, :data]
              end
            end
          end # Complete
        end # Command
      end # AGI
    end # Asterisk
  end # Component
end # Punchblock
