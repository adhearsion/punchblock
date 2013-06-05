# encoding: utf-8

module Punchblock
  module Component
    class Record < ComponentNode
      register :record, :record

      VALID_DIRECTIONS = [:duplex, :send, :recv].freeze

      # @return [String] the codec to use for recording
      attribute :format

      # @return [Integer] Controls how long the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      attribute :initial_timeout, Integer

      # @return [Integer] Controls the length of a period of silence after callers have spoken to conclude they finished.
      attribute :final_timeout, Integer

      # @return [Integer] Indicates the maximum duration for the recording.
      attribute :max_duration, Integer

      # @return [true, false] Indicates whether subsequent record will be preceded with a beep.
      attribute :start_beep, Boolean

      # @return [true, false] Whether subsequent record will start in PAUSE mode.
      attribute :start_paused, Boolean

      # @return [Symbol] the direction of media to be recorded.
      attribute :direction, Symbol
      def direction=(direction)
        if direction && !VALID_DIRECTIONS.include?(direction.to_sym)
          raise ArgumentError, "Invalid Direction (#{direction}), use: #{VALID_DIRECTIONS*' '}"
        end
        super
      end

      def rayo_attributes
        {
          'format' => format,
          'initial-timeout' => initial_timeout,
          'final-timeout' => final_timeout,
          'max-duration' => max_duration,
          'start-beep' => start_beep,
          'start-paused' => start_paused,
          'direction' => direction
        }
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

        attribute :uri
        attribute :duration, Integer
        attribute :size, Integer
      end

      class Complete
        class Success < Event::Complete::Reason
          register :success, :record_complete
        end
      end
    end
  end
end
