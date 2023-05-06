class GetProcessMem
  module Os
    class Windows
      include Sys

      attr_reader :pid

      def initialize(pid)
        @pid = pid
      end

      def memory
        BigDecimal(ProcTable.ps(pid: pid).working_set_size)
      end

      alias_method :ps_memory, :memory
    end
  end
end
