module Punchblock
  module Component
    module Tropo
      class Say < ComponentNode
        register :say, :say

        include MediaContainer

        ##
        # Creates an Rayo Say command
        #
        # @param [Hash] options
        # @option options [String, Optional] :text to speak back
        # @option options [String, Optional] :voice with which to render TTS
        # @option options [String, Optional] :ssml document to render TTS
        #
        # @return [Command::Say] an Rayo "say" command
        #
        # @example
        #   say :text => 'Hello brown cow.'
        #
        #   returns:
        #     <say xmlns="urn:xmpp:tropo:say:1">Hello brown cow.</say>
        #
        def self.new(options = {})
          super().tap do |new_node|
            case options
            when Hash
              new_node.voice = options.delete(:voice) if options[:voice]
              new_node.ssml = options.delete(:ssml) if options[:ssml]
              new_node << options.delete(:text) if options[:text]
            when Nokogiri::XML::Element
              new_node.inherit options
            end
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

        # Pauses a running Say
        #
        # @return [Command::Say::Pause] an Rayo pause message for the current Say
        #
        # @example
        #    say_obj.pause_action.to_xml
        #
        #    returns:
        #      <pause xmlns="urn:xmpp:tropo:say:1"/>
        def pause_action
          Pause.new :component_id => component_id, :call_id => call_id
        end

        ##
        # Sends an Rayo pause message for the current Say
        #
        def pause!
          raise InvalidActionError, "Cannot pause a Say that is not executing" unless executing?
          pause_action.tap do |action|
            result = write_action action
            paused! if result
          end
        end

        ##
        # Create an Rayo resume message for the current Say
        #
        # @return [Command::Say::Resume] an Rayo resume message
        #
        # @example
        #    say_obj.resume_action.to_xml
        #
        #    returns:
        #      <resume xmlns="urn:xmpp:tropo:say:1"/>
        def resume_action
          Resume.new :component_id => component_id, :call_id => call_id
        end

        ##
        # Sends an Rayo resume message for the current Say
        #
        def resume!
          raise InvalidActionError, "Cannot resume a Say that is not paused." unless paused?
          resume_action.tap do |action|
            result = write_action action
            resumed! if result
          end
        end

        class Pause < CommandNode # :nodoc:
          register :pause, :say
        end

        class Resume < CommandNode # :nodoc:
          register :resume, :say
        end

        class Complete
          class Success < Event::Complete::Reason
            register :success, :say_complete
          end
        end
      end # Say
    end # Tropo
  end # Command
end # Punchblock
