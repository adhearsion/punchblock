# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      class AGICommand
        ARG_QUOTER = /["\\]/.freeze

        attr_reader :id

        def initialize(id, channel, command, *params)
          @id, @channel, @command, @params = id, channel, command, params
        end

        # @raises RubyAMI::Error, ChannelGoneError
        def execute(ami_client)
          ami_client.send_action 'AGI', 'Channel' => @channel, 'Command' => agi_command, 'CommandID' => id
        rescue RubyAMI::Error => e
          case e.message
          when 'No such channel', /Channel (\S+) does not exist./
            raise ChannelGoneError, e.message
          else
            raise e
          end
        end

        def parse_result(event)
          parser = RubyAMI::AGIResultParser.new event['Result']
          {code: parser.code, result: parser.result, data: parser.data}
        end

        private

        def agi_command
          "#{@command} #{@params.map { |arg| quote_arg(arg) }.join(' ')}".squish
        end

        # Arguments surrounded by quotes; quotes backslash-escaped.
        # See parse_args in asterisk/res/res_agi.c (Asterisk 1.4.21.1)
        def quote_arg(arg)
          '"' + arg.to_s.gsub(ARG_QUOTER) { |m| "\\#{m}" } + '"'
        end
      end
    end
  end
end
