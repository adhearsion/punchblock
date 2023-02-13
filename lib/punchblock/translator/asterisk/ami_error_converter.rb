# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module AMIErrorConverter
        def self.convert(result = ->(e) { raise ChannelGoneError, e.message } )
          yield
        rescue RubyAMI::Error => e
          pb_logger.warn "Rescued a RubyAMI Error:\n#{e.inspect}"
          case e.message
          when 'No such channel', /Channel (\S+) does not exist./
            result.call e if result
          else
            raise e
          end
        end
      end
    end
  end
end
