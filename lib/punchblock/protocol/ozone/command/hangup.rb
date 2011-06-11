module Punchblock
  module Protocol
    module Ozone
      module Command
        ##
        # An Ozone hangup message
        #
        class Hangup < OzoneNode
          register :hangup, :core

          include HasHeaders

          def self.new(options = {})
            super().tap do |new_node|
              new_node.headers = options[:headers]
            end
          end
        end # Hangup
      end
    end # Ozone
  end # Protocol
end # Punchblock
