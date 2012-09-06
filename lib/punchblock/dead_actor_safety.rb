module Punchblock
  module DeadActorSafety
    def safe_from_dead_actors
      yield
    rescue Celluloid::DeadActorError
    end
  end
end
