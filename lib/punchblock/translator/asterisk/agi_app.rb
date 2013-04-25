require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      class AGIApp
        def initialize(app, *args)
          @app, @args = app, prepare_arguments(args)
        end

        def execute(call)
          call.execute_agi_command "EXEC #{@app}", @args
        end

        private

        def prepare_arguments(args)
          args.map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.join(',')
        end
      end
    end
  end
end
