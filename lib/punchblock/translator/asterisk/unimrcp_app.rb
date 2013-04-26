require 'punchblock/translator/asterisk/agi_app'
require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      class UniMRCPApp
        def initialize(app, *args, options)
          args.map! { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }
          args << prepare_options(options)
          @agi_app = AGIApp.new(app, *args)
        end

        def execute(call)
          @agi_app.execute call
        end

        private

        def prepare_options(options)
          options.map { |o| o.join '=' }.join '&'
        end
      end
    end
  end
end
