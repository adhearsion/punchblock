# encoding: utf-8

module Punchblock
  class URIList < SimpleDelegator
    def self.import(string)
      new string.strip.split("\n").map(&:strip)
    end

    def initialize(*list)
      super list.flatten
    end

    def to_s
      join("\n")
    end
  end
end
