# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module AMIErrorConverter
        def self.convert
          yield
        rescue RubyAMI::Error => e
          case e.message
          when 'No such channel', /Channel (\S+) does not exist./
            raise ChannelGoneError, e.message
          else
            raise e
          end
        end
      end
    end
  end
end
