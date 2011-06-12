module Punchblock
  module Protocol
    class Ozone
      ##
      # An ozone Ref message. This provides the command ID in response to execution of a command.
      #
      class Ref < OzoneNode
        register :ref, :core

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

        def attributes # :nodoc:
          [:id] + super
        end
      end # Offer
    end # Ozone
  end # Protocol
end # Punchblock
