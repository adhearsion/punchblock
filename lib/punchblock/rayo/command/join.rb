module Punchblock
  class Rayo
    module Command
      class Join < CommandNode
        register :join, :core

        ##
        # Create a join message
        #
        # @param [Hash] options
        # @option options [String, Optional] :other_call_id the call ID to join
        # @option options [String, Optional] :mixer_id the mixer name to join
        # @option options [Symbol, Optional] :direction the direction in which media should flow
        # @option options [Symbol, Optional] :media the method by which to negotiate media
        #
        # @return [Rayo::Command::Join] a formatted Rayo join command
        #
        def self.new(options = {})
          super().tap do |new_node|
            case options
            when Nokogiri::XML::Node
              new_node.inherit options
            when Hash
              options.each_pair { |k,v| new_node.send :"#{k}=", v }
            end
          end
        end

        ##
        # @return [String] the call ID to join
        def other_call_id
          read_attr :'call-id'
        end

        ##
        # @param [String] other the call ID to join
        def other_call_id=(other)
          write_attr :'call-id', other
        end

        ##
        # @return [String] the mixer name to join
        def mixer_id
          read_attr :'mixer-id'
        end

        ##
        # @param [String] other the mixer name to join
        def mixer_id=(other)
          write_attr :'mixer-id', other
        end

        ##
        # @return [String] the direction in which media should flow
        def direction
          read_attr :direction, :to_sym
        end

        ##
        # @param [String] other the direction in which media should flow. Can be :duplex, :recv or :send
        def direction=(other)
          write_attr :direction, other
        end

        ##
        # @return [String] the method by which to negotiate media
        def media
          read_attr :media, :to_sym
        end

        ##
        # @param [String] other the method by which to negotiate media. Can be :direct or :bridge
        def media=(other)
          write_attr :media, other
        end

        def inspect_attributes # :nodoc:
          [:other_call_id, :mixer_id, :direction, :media] + super
        end
      end # Join
    end # Command
  end # Rayo
end # Punchblock
