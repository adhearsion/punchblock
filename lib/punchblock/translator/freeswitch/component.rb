# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        extend ActiveSupport::Autoload

        autoload :AbstractOutput
        autoload :FliteOutput
        autoload :InlineComponent
        autoload :Input
        autoload :Output
        autoload :Record
        autoload :TTSOutput

        class Component < InlineComponent
          include Celluloid

          extend ActorHasGuardedHandlers
          execute_guarded_handlers_on_receiver

          def send_complete_event(*args)
            super
            terminate
          end
        end
      end
    end
  end
end
