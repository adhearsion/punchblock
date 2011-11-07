module Celluloid
  class Actor
    attr_reader :subject
  end

  class ActorProxy
    def actor_subject
      @actor.subject
    end
  end
end
