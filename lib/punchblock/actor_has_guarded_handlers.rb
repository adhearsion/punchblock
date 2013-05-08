module Punchblock
  module ActorHasGuardedHandlers
    def execute_guarded_handlers_on_receiver
      execute_block_on_receiver :register_handler, :register_tmp_handler, :register_handler_with_priority
    end
  end
end
