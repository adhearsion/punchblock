module Punchblock
  module Protocol
    class Ozone
      module Command
        class Transfer < OzoneNode
          register :transfer, :transfer

          include HasHeaders

          ##
          # Creates a transfer message for Ozone
          #
          # @param [Hash] options for transferring a call
          # @option options [String] :to The destination for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
          # @option options [String] :from The caller ID for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
          # @option options [Integer, Optional] :timeout How long to wait - in seconds - for an answer, busy signal, or other event to occur.
          # @option options [Boolean, Optional] :answer_on_media If set to true, the call will be considered "answered" and audio will begin playing as soon as media is received from the far end (ringing / busy signal / etc)
          # @option options [String, Optional] :terminator
          #
          # @return [Ozone::Message::Transfer] an Ozone "transfer" message
          #
          # @example
          #   Transfer.new(:to => 'sip:myapp@mydomain.com', :terminator => '#').to_xml
          #
          #   returns:
          #     <transfer xmlns="urn:xmpp:ozone:transfer:1" to="sip:myapp@mydomain.com" terminator="#"/>
          def self.new(options = {})
            super().tap do |new_node|
              options.each_pair { |k,v| new_node.send :"#{k}=", v }
            end
          end

          def to
            find('ns:to', :ns => self.class.registered_ns).map &:text
          end

          def to=(transfer_to)
            find('//ns:to', :ns => self.class.registered_ns).each &:remove
            if transfer_to
              [transfer_to].flatten.each do |i|
                to = OzoneNode.new :to
                to << i
                self << to
              end
            end
          end

          def from
            read_attr :from
          end

          def from=(transfer_from)
            write_attr :from, transfer_from
          end

          def terminator
            read_attr :terminator
          end

          def terminator=(terminator)
            write_attr :terminator, terminator
          end

          def timeout
            read_attr :timeout, :to_i
          end

          def timeout=(timeout)
            write_attr :timeout, timeout
          end

          def answer_on_media
            read_attr('answer-on-media') == 'true'
          end

          def answer_on_media=(aom)
            write_attr 'answer-on-media', aom.to_s
          end

          def attributes
            [:to, :from, :terminator, :timeout, :answer_on_media] + super
          end

          ##
          # Creates an Ozone stop message for the current Transfer
          #
          # @return [Ozone::Command::Transfer::Stop] an Ozone stop command
          #
          # @example
          #    transfer_obj.stop!.to_xml
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:ozone:transfer:1"/>
          def stop!
            Stop.new :command_id => command_id
          end

          class Action < OzoneNode
            def self.new(options = {})
              super().tap do |new_node|
                new_node.command_id = options[:command_id]
              end
            end
          end

          class Stop < Action
            register :stop, :transfer
          end

          class Complete
            class Success < Ozone::Event::Complete::Reason
              register :success, :transfer_complete
            end

            class Timeout < Ozone::Event::Complete::Reason
              register :timeout, :transfer_complete
            end

            class Terminator < Ozone::Event::Complete::Reason
              register :terminator, :transfer_complete
            end

            class Busy < Ozone::Event::Complete::Reason
              register :busy, :transfer_complete
            end

            class Reject < Ozone::Event::Complete::Reason
              register :reject, :transfer_complete
            end
          end
        end # Transfer
      end
    end # Ozone
  end # Protocol
end # Punchblock
