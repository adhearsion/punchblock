# encoding: utf-8

module Punchblock
  module Command
    class Join < CommandNode
      register :join, :core

      VALID_DIRECTIONS = [:duplex, :send, :recv].freeze

      # @return [String] the call ID to join
      attribute :call_uri
      alias :call_id= :call_uri=

      # @return [String] the mixer name to join
      attribute :mixer_name

      # @return [Boolean] Whether to beep when joined
      attribute :courtesy_tone, Boolean

      # @return [Symbol] Which direction has the options to press '*' to hangup the call
      attribute :hangup_power, Symbol
      def hangup_power=(other)
        if other && !VALID_DIRECTIONS.include?(other.to_sym)
          raise ArgumentError, "Invalid Direction (#{other.inspect}), use: #{VALID_DIRECTIONS*' '}"
        end
        super
      end

      # @param [#to_sym] other the direction in which media should flow. Can be :duplex, :recv or :send
      attribute :direction, Symbol
      def direction=(other)
        if other && !VALID_DIRECTIONS.include?(other.to_sym)
          raise ArgumentError, "Invalid Direction (#{other.inspect}), use: #{VALID_DIRECTIONS*' '}"
        end
        super
      end

      # @return [#to_sym] the method by which to negotiate media
      attribute :media, Symbol

      def rayo_attributes
        {
          'call-uri' => call_uri,
          'mixer-name' => mixer_name,
          'direction' => direction,
          'media' => media
        }
      end
    end
  end
end
