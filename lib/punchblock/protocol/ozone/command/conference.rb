module Punchblock
  module Protocol
    class Ozone
      module Command
        class Conference < CommandNode
          register :conference, :conference

          ##
          # Creates an Ozone conference command
          #
          # @param [Hash] options
          # @option options [String] :name room id to with which to create or join the conference
          # @option options [String, Optional] :audio_url URL to play to the caller as an announcement
          # @option options [String, Optional] :prompt Text to speak to the caller as an announcement
          # @option options [Boolean, Optional] :beep Whether or not the conference should hear a beep on entry/departure
          # @option options [Boolean, Optional] :mute If set to true, the user will be muted in the conference
          # @option options [Boolean, Optional] :moderator Whether or not the conference should be moderated
          # @option options [Boolean, Optional] :tone_passthrough Identifies whether or not conference members can hear the tone generated when a a key on the phone is pressed.
          # @option options [String, Optional] :terminator This is the touch-tone key (also known as "DTMF digit") used to exit the conference.
          #
          # @return [Ozone::Command::Conference] a formatted Ozone conference command
          #
          # @example
          #    conference :name => 'Please enter your postal code.',
          #               :beep => true,
          #               :terminator => '#'
          #
          #    returns:
          #      <conference xmlns="urn:xmpp:ozone:conference:1" name="1234" beep="true" terminator="#"/>
          def self.new(options = {})
            super().tap do |new_node|
              prompt    = options.delete :prompt
              audio_url = options.delete :audio_url

              new_node.announcement = {:text => prompt, :url => audio_url} if prompt || audio_url

              options.each_pair do |k,v|
                new_node.send :"#{k}=", v
              end
            end
          end

          ##
          # @return [String] the name of the conference
          #
          def name
            read_attr :name
          end

          ##
          # @param [String] name of the conference
          #
          def name=(name)
            write_attr :name, name
          end

          ##
          # @return [Boolean] Whether or not the conference should hear a beep on entry/departure
          #
          def beep
            read_attr(:beep) == 'true'
          end

          ##
          # @param [Boolean] beep Whether or not the conference should hear a beep on entry/departure
          #
          def beep=(beep)
            write_attr :beep, beep.to_s
          end

          ##
          # @return [Boolean] If set to true, the user will be muted in the conference.
          #
          def mute
            read_attr(:mute) == 'true'
          end

          ##
          # @param [Boolean] mute If set to true, the user will be muted in the conference
          #
          def mute=(mute)
            write_attr :mute, mute.to_s
          end

          ##
          # @return [String] This is the touch-tone key (also known as "DTMF digit") used to exit the conference.
          #
          def terminator
            read_attr :terminator
          end

          ##
          # @param [String] terminator This is the touch-tone key (also known as "DTMF digit") used to exit the conference.
          #
          def terminator=(terminator)
            write_attr :terminator, terminator
          end

          ##
          # @return [Boolean] Identifies whether or not conference members can hear the tone generated when a a key on the phone is pressed.
          #
          def tone_passthrough
            read_attr('tone-passthrough') == 'true'
          end

          ##
          # @param [Boolean] tone_passthrough Identifies whether or not conference members can hear the tone generated when a a key on the phone is pressed.
          #
          def tone_passthrough=(tone_passthrough)
            write_attr 'tone-passthrough', tone_passthrough.to_s
          end

          ##
          # @return [Boolean] Whether or not the conference should be moderated
          #
          def moderator
            read_attr(:moderator) == 'true'
          end

          ##
          # @param [Boolean] moderator Whether or not the conference should be moderated
          #
          def moderator=(moderator)
            write_attr :moderator, moderator.to_s
          end

          ##
          # @return [Announcement] the announcement to play to the participant on entry
          #
          def announcement
            node = find_first '//ns:announcement', :ns => self.registered_ns
            Announcement.new node if node
          end

          ##
          # @param [Hash] ann
          # @option ann [String] :text Text to speak to the caller as an announcement
          # @option ann [String] :url URL to play to the caller as an announcement
          #
          def announcement=(ann)
            self << Announcement.new(ann)
          end

          def attributes # :nodoc:
            [:name, :beep, :mute, :terminator, :tone_passthrough, :moderator, :announcement] + super
          end

          def transition_state!(event)
            super
            case event
            when OnHold
              onhold!
            when OffHold
              offhold!
            end
          end

          state_machine :mute_status, :initial => :unmuted do
            event :muted do
              transition :unmuted => :muted
            end

            event :unmuted do
              transition :muted => :unmuted
            end
          end

          state_machine :hold_status, :initial => :offhold do
            event :onhold do
              transition :offhold => :onhold
            end

            event :offhold do
              transition :onhold => :offhold
            end
          end

          class Announcement < Say
            register :announcement, :conference
          end

          class OnHold < OzoneNode
            register :'on-hold', :conference
          end

          class OffHold < OzoneNode
            register :'off-hold', :conference
          end

          class Complete
            class Kick < Ozone::Event::Complete::Reason
              register :kick, :conference_complete

              alias :details :text

              def attributes # :nodoc:
                [:details] + super
              end
            end

            class Terminator < Ozone::Event::Complete::Reason
              register :terminator, :conference_complete
            end
          end

          ##
          # Create an Ozone mute message for the current conference
          #
          # @return [Ozone::Command::Conference::Mute] an Ozone mute message
          #
          # @example
          #    conf_obj.mute_action.to_xml
          #
          #    returns:
          #      <mute xmlns="urn:xmpp:ozone:conference:1"/>
          #
          def mute_action
            Mute.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Ozone mute message for the current Conference
          #
          def mute!
            raise InvalidActionError, "Cannot mute a Conference that is already muted" if muted?
            result = connection.write call_id, mute_action, command_id
            muted! if result
          end

          ##
          # Create an Ozone unmute message for the current conference
          #
          # @return [Ozone::Command::Conference::Unmute] an Ozone unmute message
          #
          # @example
          #    conf_obj.unmute_action.to_xml
          #
          #    returns:
          #      <unmute xmlns="urn:xmpp:ozone:conference:1"/>
          #
          def unmute_action
            Unmute.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Ozone unmute message for the current Conference
          #
          def unmute!
            raise InvalidActionError, "Cannot unmute a Conference that is not muted" unless muted?
            result = connection.write call_id, unmute_action, command_id
            unmuted! if result
          end

          ##
          # Create an Ozone conference stop message
          #
          # @return [Ozone::Command::Conference::Stop] an Ozone conference stop message
          #
          # @example
          #    conf_obj.stop_action.to_xml
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:ozone:conference:1"/>
          #
          def stop_action
            Stop.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Ozone stop message for the current Conference
          #
          def stop!(options = {})
            raise InvalidActionError, "Cannot stop a Conference that is not executing" unless executing?
            connection.write call_id, stop_action, command_id
          end

          ##
          # Create an Ozone conference kick message
          #
          # @param [Hash] options
          # @option options [String] :message to explain the reason for kicking
          #
          # @return [Ozone::Command::Conference::Kick] an Ozone conference kick message
          #
          # @example
          #    conf_obj.kick_action(:message => 'bye!').to_xml
          #
          #    returns:
          #      <kick xmlns="urn:xmpp:ozone:conference:1">bye!</kick>
          #
          def kick_action(options = {})
            Kick.new options.merge(:command_id => command_id, :call_id => call_id)
          end

          ##
          # Sends an Ozone kick message for the current Conference
          #
          # @param [Hash] options
          # @option options [String] :message to explain the reason for kicking
          #
          def kick!(options = {})
            raise InvalidActionError, "Cannot kick a Conference that is not executing" unless executing?
            connection.write call_id, kick_action, command_id
          end

          class Mute < Action # :nodoc:
            register :mute, :conference
          end

          class Unmute < Action # :nodoc:
            register :unmute, :conference
          end

          class Stop < Action # :nodoc:
            register :stop, :conference
          end

          class Kick < Action # :nodoc:
            register :kick, :conference

            def self.new(options = {})
              super.tap do |new_node|
                new_node.message = options[:message]
              end
            end

            def message=(m)
              self << m if m
            end
          end

        end # Conference
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
