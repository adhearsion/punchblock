module Punchblock
  module Protocol
    class Ozone
      module Command
        class Transfer < CommandNode
          register :transfer, :transfer

          include HasHeaders

          ##
          # Creates an Ozone transfer command
          #
          # @param [Hash] options for transferring a call
          # @option options [String, Array[String]] :to The destination(s) for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com). Can be an array to hunt.
          # @option options [String] :from The caller ID for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
          # @option options [String, Optional] :terminator The string key press required to abort the transfer.
          # @option options [Integer, Optional] :timeout How long to wait - in seconds - for an answer, busy signal, or other event to occur.
          # @option options [Boolean, Optional] :answer_on_media If set to true, the call will be considered "answered" and audio will begin playing as soon as media is received from the far end (ringing / busy signal / etc)
          # @option options [Symbol, Optional] :media Rules for handling media. Can be :direct, where parties negotiate media directly, or :bridge where the media server will bridge audio, allowing media features like recording and ASR.
          # @option options [Ring, Hash, Optional] :ring to play to the caller untill connected
          #
          # @return [Ozone::Message::Transfer] an Ozone "transfer" message
          #
          # @example
          #   Transfer.new(:to => 'sip:you@yourdomain.com', :from => 'sip:myapp@mydomain.com', :terminator => '#').to_xml
          #
          #   returns:
          #     <transfer xmlns="urn:xmpp:ozone:transfer:1" from="sip:myapp@mydomain.com" terminator="#">
          #       <to>sip:you@yourdomain.com</to>
          #     </transfer>
          #
          def self.new(options = {})
            super().tap do |new_node|
              options.each_pair { |k,v| new_node.send :"#{k}=", v }
            end
          end

          ##
          # @return [Array[String]] The destination(s) for the call transfer
          #
          def to
            find('ns:to', :ns => self.class.registered_ns).map &:text
          end

          ##
          # @param [String, Array[String]] :to The destination(s) for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com). Can be an array to hunt.
          #
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

          ##
          # @return [String] The caller ID for the call transfer
          #
          def from
            read_attr :from
          end

          ##
          # @param [String, Array[String]] :to The destination(s) for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com). Can be an array to hunt.
          #
          def from=(transfer_from)
            write_attr :from, transfer_from
          end

          ##
          # @return [String] The string key press required to abort the transfer.
          #
          def terminator
            read_attr :terminator
          end

          ##
          # @param [String] terminator The string key press required to abort the transfer.
          #
          def terminator=(terminator)
            write_attr :terminator, terminator
          end

          ##
          # @return [Integer] How long to wait - in seconds - for an answer, busy signal, or other event to occur.
          #
          def timeout
            read_attr :timeout, :to_i
          end

          ##
          # @param [Integer] timeout How long to wait - in seconds - for an answer, busy signal, or other event to occur.
          #
          def timeout=(timeout)
            write_attr :timeout, timeout
          end

          ##
          # @return [Boolean] If true, the call will be considered "answered" and audio will begin playing as soon as media is received from the far end (ringing / busy signal / etc)
          #
          def answer_on_media
            read_attr('answer-on-media') == 'true'
          end

          ##
          # @param [Boolean] aom If set to true, the call will be considered "answered" and audio will begin playing as soon as media is received from the far end (ringing / busy signal / etc)
          #
          def answer_on_media=(aom)
            write_attr 'answer-on-media', aom.to_s
          end

          ##
          # @return [Symbol] Rules for handling media. Can be :direct, where parties negotiate media directly, or :bridge where the media server will bridge audio, allowing media features like recording and ASR.
          #
          def media
            read_attr 'media', :to_sym
          end

          ##
          # @param [Symbol] media Rules for handling media. Can be :direct, where parties negotiate media directly, or :bridge where the media server will bridge audio, allowing media features like recording and ASR.
          #
          def media=(media)
            write_attr 'media', media
          end

          ##
          # @return [Ring] the ringer to play to the caller while transferring
          #
          def ring
            node = find_first '//ns:ring', :ns => self.registered_ns
            Ring.new node if node
          end

          ##
          # @param [Hash] ring
          # @option ring [String] :text Text to speak to the caller as an announcement
          # @option ring [String] :url URL to play to the caller as an announcement
          #
          def ring=(ring)
            ring = Ring.new(ring) unless ring.is_a?(Ring)
            self << ring
          end

          class Ring < Say
            register :ring, :transfer
          end

          def inspect_attributes # :nodoc:
            [:to, :from, :terminator, :timeout, :answer_on_media] + super
          end

          ##
          # Creates an Ozone stop message for the current Transfer
          #
          # @return [Ozone::Command::Transfer::Stop] an Ozone stop command
          #
          # @example
          #    transfer_obj.stop_action.to_xml
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:ozone:transfer:1"/>
          #
          def stop_action
            Stop.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Ozone stop message for the current Transfer
          #
          def stop!
            raise InvalidActionError, "Cannot stop a Transfer that is not executing." unless executing?
            connection.write call_id, stop_action, command_id
          end

          class Stop < Action # :nodoc:
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
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
