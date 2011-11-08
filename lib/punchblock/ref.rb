module Punchblock
  ##
  # An rayo Ref message. This provides the command ID in response to execution of a command.
  #
  class Ref < RayoNode
    register :ref, :core

    def self.new(options = {})
      super().tap do |new_node|
        options.each_pair { |k,v| new_node.send :"#{k}=", v }
      end
    end

    ##
    # @return [String] the command ID
    #
    def id
      read_attr :id
    end

    ##
    # @param [String] ref_id the command ID
    #
    def id=(ref_id)
      write_attr :id, ref_id
    end

    def inspect_attributes # :nodoc:
      [:id] + super
    end
  end # Offer
end # Punchblock
