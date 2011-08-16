module Punchblock
  ##
  # This exception may be raised if a transport error is detected.
  class ProtocolError < StandardError
    attr_accessor :name, :text, :call_id, :component_id

    def initialize(name = nil, text = nil, call_id = nil, component_id = nil)
      @name, @text, @call_id, @component_id = name, text, call_id, component_id
    end

    def to_s
      "#<#{self.class}: name=#{name.inspect} text=#{text.inspect} call_id=#{call_id.inspect} component_id=#{component_id.inspect}>"
    end
    alias :inspect :to_s
  end
end
