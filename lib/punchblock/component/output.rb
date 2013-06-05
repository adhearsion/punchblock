# encoding: utf-8

module Punchblock
  module Component
    class Output < ComponentNode
      register :output, :output

      def inherit(xml_node)
        ssml_node = xml_node.children.first
        self.ssml = RubySpeech::SSML.import ssml_node if ssml_node
        super
      end

      # @return [String] the SSML document to render TTS
      attribute :ssml
      def ssml=(ssml)
        return unless ssml
        unless ssml.is_a?(RubySpeech::SSML::Element)
          ssml = RubySpeech::SSML.import ssml
        end
        super
      end

      # @return [String] the TTS voice to use
      attribute :voice

      # @return [Symbol] input type on which to interrupt output
      attribute :interrupt_on, Symbol

      # @return [Integer] Indicates some offset through which the output should be skipped before rendering begins.
      attribute :start_offset, Integer

      # @return [true, false] Indicates wether or not the component should be started in a paused state to be resumed at a later time.
      attribute :start_paused, Boolean, default: false

      # @return [Integer] Indicates the duration of silence that should space repeats of the rendered document.
      attribute :repeat_interval, Integer

      # @return [Integer] Indicates the number of times the output should be played.
      attribute :repeat_times, Integer

      # @return [Integer] Indicates the maximum amount of time for which the output should be allowed to run before being terminated. Includes repeats.
      attribute :max_time, Integer

      # @return [String] the rendering engine requested by the component
      attribute :renderer

      def rayo_attributes
        {
          'voice' => voice,
          'interrupt-on' => interrupt_on,
          'start-offset' => start_offset,
          'start-paused' => start_paused,
          'repeat-interval' => repeat_interval,
          'repeat-times' => repeat_times,
          'max-time' => max_time,
          'renderer' => renderer
        }
      end

      def rayo_children(root)
        root << ssml.to_xml if ssml
        super
      end

      state_machine :state do
        event :paused do
          transition :executing => :paused
        end

        event :resumed do
          transition :paused => :executing
        end
      end

      # Pauses a running Output
      #
      # @return [Command::Output::Pause] an Rayo pause message for the current Output
      #
      # @example
      #    output_obj.pause_action.to_xml
      #
      #    returns:
      #      <pause xmlns="urn:xmpp:rayo:output:1"/>
      def pause_action
        Pause.new :component_id => component_id, :target_call_id => target_call_id
      end

      ##
      # Sends an Rayo pause message for the current Output
      #
      def pause!
        raise InvalidActionError, "Cannot pause a Output that is not executing" unless executing?
        pause_action.tap do |action|
          result = write_action action
          paused! if result
        end
      end

      ##
      # Create an Rayo resume message for the current Output
      #
      # @return [Command::Output::Resume] an Rayo resume message
      #
      # @example
      #    output_obj.resume_action.to_xml
      #
      #    returns:
      #      <resume xmlns="urn:xmpp:rayo:output:1"/>
      def resume_action
        Resume.new :component_id => component_id, :target_call_id => target_call_id
      end

      ##
      # Sends an Rayo resume message for the current Output
      #
      def resume!
        raise InvalidActionError, "Cannot resume a Output that is not paused." unless paused?
        resume_action.tap do |action|
          result = write_action action
          resumed! if result
        end
      end

      class Pause < CommandNode # :nodoc:
        register :pause, :output
      end

      class Resume < CommandNode # :nodoc:
        register :resume, :output
      end

      ##
      # Creates an Rayo seek message for the current Output
      #
      # @return [Command::Output::Seek] a Rayo seek message
      #
      # @example
      #    output_obj.seek_action.to_xml
      #
      #    returns:
      #      <seek xmlns="urn:xmpp:rayo:output:1"/>
      def seek_action(options = {})
        Seek.new({ :component_id => component_id, :target_call_id => target_call_id }.merge(options)).tap do |s|
          s.original_component = self
        end
      end

      ##
      # Sends a Rayo seek message for the current Output
      #
      def seek!(options = {})
        raise InvalidActionError, "Cannot seek an Output that is already seeking." if seeking?
        seek_action(options).tap do |action|
          write_action action
        end
      end

      state_machine :seek_status, :initial => :not_seeking do
        event :seeking do
          transition :not_seeking => :seeking
        end

        event :stopped_seeking do
          transition :seeking => :not_seeking
        end
      end

      class Seek < CommandNode # :nodoc:
        register :seek, :output

        attribute :direction
        attribute :amount

        def request!
          source.seeking!
          super
        end

        def execute!
          source.stopped_seeking!
          super
        end

        def rayo_attributes
          {'direction' => direction, 'amount' => amount}
        end
      end

      ##
      # Creates an Rayo speed up message for the current Output
      #
      # @return [Command::Output::SpeedUp] a Rayo speed up message
      #
      # @example
      #    output_obj.speed_up_action.to_xml
      #
      #    returns:
      #      <speed-up xmlns="urn:xmpp:rayo:output:1"/>
      def speed_up_action
        SpeedUp.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
          s.original_component = self
        end
      end

      ##
      # Sends a Rayo speed up message for the current Output
      #
      def speed_up!
        raise InvalidActionError, "Cannot speed up an Output that is already speeding." unless not_speeding?
        speed_up_action.tap do |action|
          write_action action
        end
      end

      ##
      # Creates an Rayo slow down message for the current Output
      #
      # @return [Command::Output::SlowDown] a Rayo slow down message
      #
      # @example
      #    output_obj.slow_down_action.to_xml
      #
      #    returns:
      #      <speed-down xmlns="urn:xmpp:rayo:output:1"/>
      def slow_down_action
        SlowDown.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
          s.original_component = self
        end
      end

      ##
      # Sends a Rayo slow down message for the current Output
      #
      def slow_down!
        raise InvalidActionError, "Cannot slow down an Output that is already speeding." unless not_speeding?
        slow_down_action.tap do |action|
          write_action action
        end
      end

      state_machine :speed_status, :initial => :not_speeding do
        event :speeding_up do
          transition :not_speeding => :speeding_up
        end

        event :slowing_down do
          transition :not_speeding => :slowing_down
        end

        event :stopped_speeding do
          transition [:speeding_up, :slowing_down] => :not_speeding
        end
      end

      class SpeedUp < CommandNode # :nodoc:
        register :'speed-up', :output

        def request!
          source.speeding_up!
          super
        end

        def execute!
          source.stopped_speeding!
          super
        end
      end

      class SlowDown < CommandNode # :nodoc:
        register :'speed-down', :output

        def request!
          source.slowing_down!
          super
        end

        def execute!
          source.stopped_speeding!
          super
        end
      end

      ##
      # Creates an Rayo volume up message for the current Output
      #
      # @return [Command::Output::VolumeUp] a Rayo volume up message
      #
      # @example
      #    output_obj.volume_up_action.to_xml
      #
      #    returns:
      #      <volume-up xmlns="urn:xmpp:rayo:output:1"/>
      def volume_up_action
        VolumeUp.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
          s.original_component = self
        end
      end

      ##
      # Sends a Rayo volume up message for the current Output
      #
      def volume_up!
        raise InvalidActionError, "Cannot volume up an Output that is already voluming." unless not_voluming?
        volume_up_action.tap do |action|
          write_action action
        end
      end

      ##
      # Creates an Rayo volume down message for the current Output
      #
      # @return [Command::Output::VolumeDown] a Rayo volume down message
      #
      # @example
      #    output_obj.volume_down_action.to_xml
      #
      #    returns:
      #      <volume-down xmlns="urn:xmpp:rayo:output:1"/>
      def volume_down_action
        VolumeDown.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
          s.original_component = self
        end
      end

      ##
      # Sends a Rayo volume down message for the current Output
      #
      def volume_down!
        raise InvalidActionError, "Cannot volume down an Output that is already voluming." unless not_voluming?
        volume_down_action.tap do |action|
          write_action action
        end
      end

      state_machine :volume_status, :initial => :not_voluming do
        event :voluming_up do
          transition :not_voluming => :voluming_up
        end

        event :voluming_down do
          transition :not_voluming => :voluming_down
        end

        event :stopped_voluming do
          transition [:voluming_up, :voluming_down] => :not_voluming
        end
      end

      class VolumeUp < CommandNode # :nodoc:
        register :'volume-up', :output

        def request!
          source.voluming_up!
          super
        end

        def execute!
          source.stopped_voluming!
          super
        end
      end

      class VolumeDown < CommandNode # :nodoc:
        register :'volume-down', :output

        def request!
          source.voluming_down!
          super
        end

        def execute!
          source.stopped_voluming!
          super
        end
      end

      class Complete
        class Success < Event::Complete::Reason
          register :success, :output_complete
        end
      end
    end # Output
  end # Command
end # Punchblock
