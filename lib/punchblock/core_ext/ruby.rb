class Hash
  def select(&block)
    val = super(&block)
    if val.is_a?(Array)
      val = val.inject({}) do |accumulator, element|
        accumulator[element[0]] = element[1]
        accumulator
      end
    end
    val
  end
end

class NullObject
  def method_missing(*args)
    self
  end
end

class Object
  def pb_logger
    Punchblock.logger
  end
end
