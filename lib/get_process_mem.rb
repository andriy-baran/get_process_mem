require 'pathname'
require 'bigdecimal'
require 'get_process_mem/os_detector'
require 'get_process_mem/bytes'

if GetProcessMem::OsDetector.runs_on_darwin?
  begin
    require 'get_process_mem/os/darwin'
  rescue LoadError => e
    message = "Please add `ffi` to your Gemfile for darwin (macos) machines\n"
    message << e.message
    raise e, message
  end
end

if GetProcessMem::OsDetector.runs_on_windows?
  begin
    require 'sys/proctable'
  rescue LoadError => e
    message = "Please add `sys-proctable` to your Gemfile for windows machines\n"
    message << e.message
    raise e, message
  end
end

# Cribbed from Unicorn Worker Killer, thanks!
class GetProcessMem
  include Sys if OsDetector.runs_on_windows?
  ROUND_UP   = BigDecimal("0.5")
  attr_reader :pid

  def initialize(pid = Process.pid)
    @status_file  = Pathname.new "/proc/#{pid}/status"
    @process_file = Pathname.new "/proc/#{pid}/smaps"
    @pid          = pid
    @linux        = @status_file.exist?
  end

  def linux?
    @linux
  end

  def bytes
    memory =   linux_status_memory if linux?
    memory ||= darwin_memory if OsDetector.runs_on_darwin?
    memory ||= ps_memory
  end

  def kb(b = bytes)
    Bytes.new(b).kb
  end

  def mb(b = bytes)
    Bytes.new(b).mb
  end

  def gb(b = bytes)
    Bytes.new(b).gb
  end

  def inspect
    b = Bytes.new(bytes)
    "#<#{self.class}:0x%08x @mb=#{ b.mb } @gb=#{ b.gb } @kb=#{ b.kb } @bytes=#{b.b}>" % (object_id * 2)
  end

  # linux stores memory info in a file "/proc/#{pid}/status"
  # If it's available it uses less resources than shelling out to ps
  def linux_status_memory(file = @status_file)
    line = file.each_line.detect {|line| line.start_with? 'VmRSS'.freeze }
    return unless line
    return unless (_name, value, unit = line.split(nil)).length == 3
    Bytes::CONVERSION[unit.downcase!] * value.to_i
  rescue Errno::EACCES, Errno::ENOENT
    0
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

  # Pull memory from `ps` command, takes more resources and can freeze
  # in low memory situations
  def ps_memory
    if RUNS_ON_WINDOWS
      ProcTable.ps(pid: pid).working_set_size.to_d
    else
      mem = `ps -o rss= -p #{pid}`
      Bytes::KB_TO_BYTE * BigDecimal(mem == "" ? 0 : mem)
    end
  end

  def darwin_memory
    Os::Darwin.resident_size(pid)
  rescue Errno::EPERM
    nil
  end
end
