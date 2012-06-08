module Punchblock
  module DeadActorSafety
    def safe_from_dead_actors
      yield
    rescue Celluloid::DeadActorError => e
      pb_logger.error e
    end
  end
end
