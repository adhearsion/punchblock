module Punchblock
  class Rayo
    module Component
      class Record < ComponentNode
        register :record, :record

        ##
        # Creates an Rayo Record command
        #
        # @param [Hash] options
        # @option options [String, Optional] :text to speak back
        # @option options [String, Optional] :voice with which to render TTS
        # @option options [Audio, Optional] :audio to play
        # @option options [String, Optional] :ssml document to render TTS
        #
        # @return [Rayo::Command::Record] an Rayo "record" command
        #
        # @example
        #   record :text => 'Hello brown cow.'
        #
        #   returns:
        #     <record xmlns="urn:xmpp:rayo:record:1">Hello brown cow.</record>
        #
        def self.new(options = {})
          super().tap do |new_node|
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end

        ##
        # @return [String] the codec to use for recording
        #
        def final_timeout
          read_attr :'final-timeout', :to_i
        end

        ##
        # @param [String] codec to use for recording
        #
        def final_timeout=(timeout)
          write_attr :'final-timeout', timeout
        end

        ##
        # @return [String] the codec to use for recording
        #
        def format
          read_attr :format
        end

        ##
        # @param [String] codec to use for recording
        #
        def format=(format)
          write_attr :format, format
        end

        ##
        # @return [String] the codec to use for recording
        #
        def initial_timeout
          read_attr :'initial-timeout', :to_i
        end

        ##
        # @param [String] codec to use for recording
        #
        def initial_timeout=(timeout)
          write_attr :'initial-timeout', timeout
        end

        ##
        # @return [String] the codec to use for recording
        #
        def max_duration
          read_attr :'max-duration', :to_i
        end

        ##
        # @param [String] codec to use for recording
        #
        def max_duration=(other)
          write_attr :'max-duration', other
        end

        ##
        # @return [String] the codec to use for recording
        #
        def start_beep
          read_attr(:'start-beep') == 'true'
        end

        ##
        # @param [String] codec to use for recording
        #
        def start_beep=(sb)
          write_attr :'start-beep', sb
        end

        ##
        # @return [String] the codec to use for recording
        #
        def stop_beep
          read_attr(:'stop-beep') == 'true'
        end

        ##
        # @param [String] codec to use for recording
        #
        def stop_beep=(sb)
          write_attr :'stop-beep', sb
        end

        ##
        # @return [String] the codec to use for recording
        #
        def start_paused
          read_attr(:'start-paused') == 'true'
        end

        ##
        # @param [String] codec to use for recording
        #
        def start_paused=(other)
          write_attr :'start-paused', other
        end

        def inspect_attributes # :nodoc:
          [:final_timeout, :format, :initial_timeout, :max_duration, :start_beep, :start_paused, :stop_beep] + super
        end

        state_machine :state do
          event :paused do
            transition :executing => :paused
          end

          event :resumed do
            transition :paused => :executing
          end
        end

        # Pauses a running Record
        #
        # @return [Rayo::Command::Record::Pause] an Rayo pause message for the current Record
        #
        # @example
        #    record_obj.pause_action.to_xml
        #
        #    returns:
        #      <pause xmlns="urn:xmpp:rayo:record:1"/>
        def pause_action
          Pause.new :component_id => component_id, :call_id => call_id
        end

        ##
        # Sends an Rayo pause message for the current Record
        #
        def pause!
          raise InvalidActionError, "Cannot pause a Record that is not executing." unless executing?
          result = connection.write call_id, pause_action, component_id
          paused! if result
        end

        ##
        # Create an Rayo resume message for the current Record
        #
        # @return [Rayo::Command::Record::Resume] an Rayo resume message
        #
        # @example
        #    record_obj.resume_action.to_xml
        #
        #    returns:
        #      <resume xmlns="urn:xmpp:rayo:record:1"/>
        def resume_action
          Resume.new :component_id => component_id, :call_id => call_id
        end

        ##
        # Sends an Rayo resume message for the current Record
        #
        def resume!
          raise InvalidActionError, "Cannot resume a Record that is not paused." unless paused?
          result = connection.write call_id, resume_action, component_id
          resumed! if result
        end

        ##
        # Creates an Rayo stop message for the current Record
        #
        # @return [Rayo::Command::Record::Stop] an Rayo stop message
        #
        # @example
        #    record_obj.stop_action.to_xml
        #
        #    returns:
        #      <stop xmlns="urn:xmpp:rayo:record:1"/>
        def stop_action
          Stop.new :component_id => component_id, :call_id => call_id
        end

        ##
        # Sends an Rayo stop message for the current Record
        #
        def stop!
          raise InvalidActionError, "Cannot stop a Record that is not executing." unless executing?
          connection.write call_id, stop_action, component_id
        end

        class Pause < Action # :nodoc:
          register :pause, :record
        end

        class Resume < Action # :nodoc:
          register :resume, :record
        end

        class Recording < RayoNode
          register :recording, :record_complete

          def uri
            read_attr :uri
          end

          def inspect_attributes # :nodoc:
            [:uri] + super
          end
        end

        class Complete
          class Success < Rayo::Event::Complete::Reason
            register :success, :record_complete
          end
        end
      end # Record
    end # Command
  end # Rayo
end # Punchblock
