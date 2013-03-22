# encoding: utf-8

module Punchblock
  module Component
    class Output < ComponentNode
      register :output, :output

      ##
      # Creates an Rayo Output command
      #
      # @param [Hash] options
      # @option options [String, Optional] :text to speak back
      # @option options [Document] :render_document document to render TTS
      # @option options [Symbol] :interrupt_on input type on which to interrupt output. May be :speech, :dtmf or :any
      # @option options [Integer] :start_offset Indicates some offset through which the output should be skipped before rendering begins.
      # @option options [true, false] :start_paused Indicates wether or not the component should be started in a paused state to be resumed at a later time.
      # @option options [Integer] :repeat_interval Indicates the duration of silence that should space repeats of the rendered document.
      # @option options [Integer] :repeat_times Indicates the number of times the output should be played.
      # @option options [Integer] :max_time Indicates the maximum amount of time for which the output should be allowed to run before being terminated. Includes repeats.
      #
      # @return [Command::Output] an Rayo "output" command
      #
      # @example
      #   output :render_document => {:content => RubySpeech::SSML.draw }
      #
      #   returns:
      #     <output xmlns="urn:xmpp:rayo:output:1">Hello brown cow.</output>
      #
      def self.new(options = {})
        super().tap do |new_node|
          case options
          when Hash
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          when Nokogiri::XML::Element
            new_node.inherit options
          end
        end
      end

      ##
      # @return [String] the TTS voice to use
      #
      def voice
        read_attr :voice
      end

      ##
      # @param [String] voice to use when rendering TTS
      #
      def voice=(voice)
        write_attr :voice, voice
      end

      ##
      # @return [Symbol] input type on which to interrupt output
      #
      def interrupt_on
        read_attr :'interrupt-on', :to_sym
      end

      ##
      # @param [Symbol] other input type on which to interrupt output. May be :speech, :dtmf or :any
      #
      def interrupt_on=(other)
        write_attr :'interrupt-on', other
      end

      ##
      # @return [Integer] Indicates some offset through which the output should be skipped before rendering begins.
      #
      def start_offset
        read_attr :'start-offset', :to_i
      end

      ##
      # @param [Integer] other Indicates some offset through which the output should be skipped before rendering begins.
      #
      def start_offset=(other)
        write_attr :'start-offset', other, :to_i
      end

      ##
      # @return [true, false] Indicates wether or not the component should be started in a paused state to be resumed at a later time.
      #
      def start_paused
        read_attr(:'start-paused') == 'true'
      end

      ##
      # @param [true, false] other Indicates wether or not the component should be started in a paused state to be resumed at a later time.
      #
      def start_paused=(other)
        write_attr :'start-paused', other, :to_s
      end

      ##
      # @return [Integer] Indicates the duration of silence that should space repeats of the rendered document.
      #
      def repeat_interval
        read_attr :'repeat-interval', :to_i
      end

      ##
      # @param [Integer] other Indicates the duration of silence that should space repeats of the rendered document.
      #
      def repeat_interval=(other)
        write_attr :'repeat-interval', other, :to_i
      end

      ##
      # @return [Integer] Indicates the number of times the output should be played.
      #
      def repeat_times
        read_attr :'repeat-times', :to_i
      end

      ##
      # @param [Integer] other Indicates the number of times the output should be played.
      #
      def repeat_times=(other)
        write_attr :'repeat-times', other, :to_i
      end

      ##
      # @return [Integer] Indicates the maximum amount of time for which the output should be allowed to run before being terminated. Includes repeats.
      #
      def max_time
        read_attr :'max-time', :to_i
      end

      ##
      # @param [Integer] other Indicates the maximum amount of time for which the output should be allowed to run before being terminated. Includes repeats.
      #
      def max_time=(other)
        write_attr :'max-time', other, :to_i
      end

      ##
      # @return [String] the rendering engine requested by the component
      #
      def renderer
        read_attr :renderer
      end

      ##
      # @param [String] the rendering engine to use with this component
      #
      def renderer=(renderer)
        write_attr :renderer, renderer
      end

      def inspect_attributes
        super + [:voice, :render_documents, :interrupt_on, :start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time, :renderer]
      end

      ##
      # @return [Document] the document to render
      #
      def render_documents
        nodes = find 'ns:document', :ns => self.class.registered_ns
        nodes.map { |node| Document.new node }
      end

      ##
      # @param [Hash] other
      # @option other [String] :content_type the document content type
      # @option other [String] :value the output doucment
      # @option other [String] :url the url from which to fetch the document
      #
      def render_document=(other)
        self.render_documents = [other].compact
      end

      ##
      # @param[Array<Hash>] others
      # @see #render_document= for hash format
      #
      def render_documents=(others)
        remove_children :document
        others.each do |other|
          document = Document.new(other) unless other.is_a?(Document)
          self << document
        end
      end

      def ssml=(other)
        self.render_document = {:value => other}
      end

      class Document < RayoNode
        ##
        # @param [Hash] options
        # @option options [String] :content_type the document content type
        # @option options [String] :value the output document
        # @option options [String] :url the url from which to fetch the document
        #
        def self.new(options = {})
          super(:document).tap do |new_node|
            case options
            when Nokogiri::XML::Node
              new_node.inherit options
            when Hash
              new_node.content_type = options[:content_type]
              new_node.value = options[:value]
              new_node.url = options[:url]
            end
          end
        end

        ##
        # @return [String] the URL from which the fetch the grammar
        #
        def url
          read_attr 'url'
        end

        ##
        # @param [String] other the URL from which the fetch the grammar
        #
        def url=(other)
          write_attr 'url', other
        end

        ##
        # @return [String] the document content type
        #
        def content_type
          read_attr 'content-type'
        end

        ##
        # @param [String] content_type Defaults to SSML
        #
        def content_type=(content_type)
          return unless content_type
          write_attr 'content-type', content_type
        end

        ##
        # @return [String, RubySpeech::SSML::Speak] the document
        def value
          return nil unless content.present?
          if ssml?
            RubySpeech::SSML.import content
          else
            content
          end
        end

        ##
        # @param [String, RubySpeech::SSML::Speak] value the document
        def value=(value)
          return unless value
          self.content_type = ssml_content_type unless self.content_type
          if ssml? && !value.is_a?(RubySpeech::SSML::Element)
            value = RubySpeech::SSML.import value
          end
          Nokogiri::XML::Builder.with(self) do |xml|
            xml.cdata " #{value} "
          end
        end

        def inspect_attributes # :nodoc:
          [:url, :content_type, :value] + super
        end

        private

        def ssml_content_type
          'application/ssml+xml'
        end

        def ssml?
          content_type == ssml_content_type
        end
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

        def self.new(options = {})
          super.tap do |new_node|
            new_node.direction  = options[:direction]
            new_node.amount     = options[:amount]
          end
        end

        def direction=(other)
          write_attr :direction, other
        end

        def amount=(other)
          write_attr :amount, other
        end

        def request!
          source.seeking!
          super
        end

        def execute!
          source.stopped_seeking!
          super
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
        class Finish < Event::Complete::Reason
          register :finish, :output_complete
        end

        class MaxTime < Event::Complete::Reason
          register :'max-time', :output_complete
        end
      end
    end # Output
  end # Command
end # Punchblock
