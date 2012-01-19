module Punchblock
  class Event
    class DTMF < Event
      register :dtmf, :core

      def signal
        read_attr :signal
      end

      def signal=(other)
        write_attr :signal, other
      end

      def inspect_attributes # :nodoc:
        [:signal] + super
      end
    end # End
  end
end # Punchblock
