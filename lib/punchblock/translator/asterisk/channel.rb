# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      class Channel < SimpleDelegator
        CHANNEL_NORMALIZATION_REGEXP = /^(?<prefix>Bridge\/)*(?<name>[^<>]*)(?<suffix><.*>)*$/.freeze

        def name
          matchdata[:name]
        end

        def prefix
          matchdata[:prefix]
        end

        def suffix
          matchdata[:suffix]
        end

        def bridged?
          @bridged ||= (prefix || suffix)
        end

        private

        def matchdata
          @matchdata ||= __getobj__.match(CHANNEL_NORMALIZATION_REGEXP)
        end
      end
    end
  end
end
