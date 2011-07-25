module Punchblock
  module Protocol
    class Rayo
      module Command
        class Conference < CommandNode
          register :conference, :conference

          ##
          # Creates an Rayo conference command
          #
          # @param [Hash] options
          # @option options [String] :name room id to with which to create or join the conference
          # @option options [Announcement, Hash, Optional] :announcement to play on entry
          # @option options [Music, Hash, Optional] :music to play to the participant when no moderator is present
          # @option options [Boolean, Optional] :mute If set to true, the user will be muted in the conference
          # @option options [Boolean, Optional] :moderator Whether or not the conference should be moderated
          # @option options [Boolean, Optional] :tone_passthrough Identifies whether or not conference members can hear the tone generated when a a key on the phone is pressed.
          # @option options [String, Optional] :terminator This is the touch-tone key (also known as "DTMF digit") used to exit the conference.
          #
          # @return [Rayo::Command::Conference] a formatted Rayo conference command
          #
          # @example
          #    conference :name => 'the_one_true_conference', :terminator => '#'
          #
          #    returns:
          #      <conference xmlns="urn:xmpp:rayo:conference:1" name="the_one_true_conference" terminator="#"/>
          def self.new(options = {})
            super().tap do |new_node|
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
          # @param [Announcement, Hash] ann
          # @option ann [String] :text Text to speak to the caller as an announcement
          # @option ann [String] :url URL to play to the caller as an announcement
          #
          def announcement=(ann)
            ann = Announcement.new(ann) unless ann.is_a? Announcement
            self << ann
          end

          ##
          # @return [Music] the music to play to the participant on entry if there's no moderator present
          #
          def music
            node = find_first '//ns:music', :ns => self.registered_ns
            Music.new node if node
          end

          ##
          # @param [Music, Hash] m
          # @option m [String] :text Text to speak to the caller
          # @option m [String] :url URL to play to the caller
          #
          def music=(m)
            m = Music.new(m) unless m.is_a? Announcement
            self << m
          end

          def inspect_attributes # :nodoc:
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

          state_machine :state do
            after_transition :new => :requested do |command, transition|
              command.mute ? command.muted! : command.unmuted!
            end
          end

          state_machine :mute_status, :initial => :unknown_mute do
            event :muted do
              transition [:unmuted, :unknown_mute] => :muted
            end

            event :unmuted do
              transition [:muted, :unknown_mute] => :unmuted
            end
          end

          state_machine :hold_status, :initial => :unknown_hold do
            event :onhold do
              transition [:offhold, :unknown_hold] => :onhold
            end

            event :offhold do
              transition [:onhold, :unknown_hold] => :offhold
            end
          end

          class Announcement < Say
            register :announcement, :conference
          end

          class Music < Say
            register :music, :conference
          end

          class OnHold < RayoNode
            register :'on-hold', :conference
          end

          class OffHold < RayoNode
            register :'off-hold', :conference
          end

          class Complete
            class Kick < Rayo::Event::Complete::Reason
              register :kick, :conference_complete

              alias :details :text

              def inspect_attributes # :nodoc:
                [:details] + super
              end
            end

            class Terminator < Rayo::Event::Complete::Reason
              register :terminator, :conference_complete
            end
          end

          ##
          # Create an Rayo mute message for the current conference
          #
          # @return [Rayo::Command::Conference::Mute] an Rayo mute message
          #
          # @example
          #    conf_obj.mute_action.to_xml
          #
          #    returns:
          #      <mute xmlns="urn:xmpp:rayo:conference:1"/>
          #
          def mute_action
            Mute.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Rayo mute message for the current Conference
          #
          def mute!
            raise InvalidActionError, "Cannot mute a Conference that is already muted" if muted?
            result = connection.write call_id, mute_action, command_id
            muted! if result
          end

          ##
          # Create an Rayo unmute message for the current conference
          #
          # @return [Rayo::Command::Conference::Unmute] an Rayo unmute message
          #
          # @example
          #    conf_obj.unmute_action.to_xml
          #
          #    returns:
          #      <unmute xmlns="urn:xmpp:rayo:conference:1"/>
          #
          def unmute_action
            Unmute.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Rayo unmute message for the current Conference
          #
          def unmute!
            raise InvalidActionError, "Cannot unmute a Conference that is not muted" unless muted?
            result = connection.write call_id, unmute_action, command_id
            unmuted! if result
          end

          ##
          # Create an Rayo conference stop message
          #
          # @return [Rayo::Command::Conference::Stop] an Rayo conference stop message
          #
          # @example
          #    conf_obj.stop_action.to_xml
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:rayo:conference:1"/>
          #
          def stop_action
            Stop.new :command_id => command_id, :call_id => call_id
          end

          ##
          # Sends an Rayo stop message for the current Conference
          #
          def stop!(options = {})
            raise InvalidActionError, "Cannot stop a Conference that is not executing" unless executing?
            connection.write call_id, stop_action, command_id
          end

          ##
          # Create an Rayo conference kick message
          #
          # @param [Hash] options
          # @option options [String] :message to explain the reason for kicking
          #
          # @return [Rayo::Command::Conference::Kick] an Rayo conference kick message
          #
          # @example
          #    conf_obj.kick_action(:message => 'bye!').to_xml
          #
          #    returns:
          #      <kick xmlns="urn:xmpp:rayo:conference:1">bye!</kick>
          #
          def kick_action(options = {})
            Kick.new options.merge(:command_id => command_id, :call_id => call_id)
          end

          ##
          # Sends an Rayo kick message for the current Conference
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
    end # Rayo
  end # Protocol
end # Punchblock
