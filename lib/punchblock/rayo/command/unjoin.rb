module Punchblock
  class Rayo
    module Command
      class Unjoin < CommandNode
        register :unjoin, :core

        ##
        # Create an ujoin message
        #
        # @param [Hash] options
        # @option options [String, Optional] :other_call_id the call ID to unjoin
        # @option options [String, Optional] :mixer_id the mixer name to unjoin
        #
        # @return [Rayo::Command::Unjoin] a formatted Rayo unjoin command
        #
        def self.new(options = {})
          super().tap do |new_node|
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end

        ##
        # @return [String] the call ID to unjoin
        def other_call_id
          read_attr :'call-id'
        end

        ##
        # @param [String] other the call ID to unjoin
        def other_call_id=(other)
          write_attr :'call-id', other
        end

        ##
        # @return [String] the mixer name to unjoin
        def mixer_id
          read_attr :'mixer-id'
        end

        ##
        # @param [String] other the mixer name to unjoin
        def mixer_id=(other)
          write_attr :'mixer-id', other
        end

        def inspect_attributes # :nodoc:
          [:other_call_id, :mixer_id] + super
        end
      end # Unjoin
    end # Command
  end # Rayo
end # Punchblock
