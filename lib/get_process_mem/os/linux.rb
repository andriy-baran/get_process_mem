class GetProcessMem
  module Os
    class Linux
      attr_reader :pid

      def initialize(pid)
        @pid = pid
        @status_file = Pathname.new("/proc/#{pid}/status")
        @process_file = Pathname.new("/proc/#{pid}/smaps")
      end

      def memory(file = @status_file)
        line = file.each_line.detect {|line| line.start_with? 'VmRSS'.freeze }
        return unless line
        return unless (_name, value, unit = line.split(nil)).length == 3
        Bytes::CONVERSION[unit.downcase!] * value.to_i
      rescue Errno::EACCES, Errno::ENOENT
        0
      end

      def ps_memory
        mem = `ps -o rss= -p #{pid}`
        Bytes::KB_TO_BYTE * BigDecimal(mem == "" ? 0 : mem)
      end

      # linux stores detailed memory info in a file "/proc/#{pid}/smaps"
      def linux_memory(file = @process_file)
        lines = file.each_line.select {|line| line.match(/^Rss/) }
        return if lines.empty?
        lines.reduce(0) do |sum, line|
          line.match(/(?<value>(\d*\.{0,1}\d+))\s+(?<unit>\w\w)/) do |m|
            value = BigDecimal(m[:value]) + ROUND_UP
            unit  = m[:unit].downcase
            sum  += Bytes::CONVERSION[unit] * value
          end
          sum
        end
      rescue Errno::EACCES
        0
      end
    end
  end
end
