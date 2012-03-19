# encoding: utf-8

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
