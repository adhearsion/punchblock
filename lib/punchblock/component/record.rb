# encoding: utf-8

module Punchblock
  module Component
    class Record < ComponentNode
      register :record, :record

      ##
      # Creates an Rayo Record command
      #
      # @param [Hash] options
      # @option options [String] :format to use for recording
      # @option options [Integer] :initial_timeout Controls how long the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      # @option options [Integer] :final_timeout Controls the length of a period of silence after callers have spoken to conclude they finished.
      # @option options [Integer] :max_duration Indicates the maximum duration for the recording.
      # @option options [true, false] :start_beep Indicates whether subsequent record will be preceded with a beep.
      # @option options [true, false] :start_paused Whether subsequent record will start in PAUSE mode.
      #
      # @return [Command::Record] a Rayo "record" command
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
      # @return [Integer] Controls the length of a period of silence after callers have spoken to conclude they finished.
      #
      def final_timeout
        read_attr :'final-timeout', :to_i
      end

      ##
      # @param [Integer] timeout Controls the length of a period of silence after callers have spoken to conclude they finished.
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
      # @return [Integer] Controls how long the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      #
      def initial_timeout
        read_attr :'initial-timeout', :to_i
      end

      ##
      # @param [Integer] timeout Controls how long the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      #
      def initial_timeout=(timeout)
        write_attr :'initial-timeout', timeout
      end

      ##
      # @return [Integer] Indicates the maximum duration for the recording.
      #
      def max_duration
        read_attr :'max-duration', :to_i
      end

      ##
      # @param [Integer] other Indicates the maximum duration for the recording.
      #
      def max_duration=(other)
        write_attr :'max-duration', other
      end

      ##
      # @return [true, false] Indicates whether subsequent record will be preceded with a beep.
      #
      def start_beep
        read_attr(:'start-beep') == 'true'
      end

      ##
      # @param [true, false] sb Indicates whether subsequent record will be preceded with a beep.
      #
      def start_beep=(sb)
        write_attr :'start-beep', sb
      end

      ##
      # @return [true, false] Whether subsequent record will start in PAUSE mode.
      #
      def start_paused
        read_attr(:'start-paused') == 'true'
      end

      ##
      # @param [true, false] other Whether subsequent record will start in PAUSE mode.
      #
      def start_paused=(other)
        write_attr :'start-paused', other
      end

      def inspect_attributes # :nodoc:
        [:final_timeout, :format, :initial_timeout, :max_duration, :start_beep, :start_paused] + super
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
      # @return [Command::Record::Pause] an Rayo pause message for the current Record
      #
      # @example
      #    record_obj.pause_action.to_xml
      #
      #    returns:
      #      <pause xmlns="urn:xmpp:rayo:record:1"/>
      def pause_action
        Pause.new :component_id => component_id, :target_call_id => target_call_id
      end

      ##
      # Sends an Rayo pause message for the current Record
      #
      def pause!
        raise InvalidActionError, "Cannot pause a Record that is not executing" unless executing?
        pause_action.tap do |action|
          result = write_action action
          paused! if result
        end
      end

      ##
      # Create an Rayo resume message for the current Record
      #
      # @return [Command::Record::Resume] an Rayo resume message
      #
      # @example
      #    record_obj.resume_action.to_xml
      #
      #    returns:
      #      <resume xmlns="urn:xmpp:rayo:record:1"/>
      def resume_action
        Resume.new :component_id => component_id, :target_call_id => target_call_id
      end

      ##
      # Sends an Rayo resume message for the current Record
      #
      def resume!
        raise InvalidActionError, "Cannot resume a Record that is not paused." unless paused?
        resume_action.tap do |action|
          result = write_action action
          resumed! if result
        end
      end

      ##
      # Directly returns the recording for the component
      # @return [Punchblock::Component::Record::Recording] The recording object
      #
      def recording
        complete_event.recording
      end

      ##
      # Directly returns the recording URI for the component
      # @return [String] The recording URI
      #
      def recording_uri
        recording.uri
      end

      class Pause < CommandNode # :nodoc:
        register :pause, :record
      end

      class Resume < CommandNode # :nodoc:
        register :resume, :record
      end

      class Recording < Event
        register :recording, :record_complete

        def uri
          read_attr :uri
        end

        def uri=(other)
          write_attr :uri, other
        end

        def duration
          read_attr :duration, :to_i
        end

        def size
          read_attr :size, :to_i
        end

        def inspect_attributes # :nodoc:
          [:uri, :duration, :size] + super
        end
      end

      class Complete
        class Success < Event::Complete::Reason
          register :success, :record_complete
        end

        class IniTimeout < Event::Complete::Reason
          register :ini_timeout, :record_complete
        end

        class Timeout < Event::Complete::Reason
          register :timeout, :record_complete
        end
      end
    end # Record
  end # Command
end # Punchblock
