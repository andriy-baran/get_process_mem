require 'pathname'
require 'bigdecimal'
require 'forwardable'
require 'get_process_mem/os_detector'
require 'get_process_mem/bytes'
require 'get_process_mem/os/linux'


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
  require 'get_process_mem/os/windows'
end

# Cribbed from Unicorn Worker Killer, thanks!
class GetProcessMem
  extend Forwardable

  ROUND_UP   = BigDecimal("0.5")

  attr_reader :pid

  def_delegators :@platform, :memory, :ps_memory

  def initialize(pid = Process.pid)
    @pid          = pid
    @platform     = GetProcessMem::Os.const_get(OsDetector.platform_name).new(pid)
    @linux        = OsDetector.platform_name == :Linux
  end

  def linux?
    @linux
  end

  def bytes
    @platform.memory
  end

  def linux_memory(file = nil)
    GetProcessMem::Os::Linux.new(pid).linux_memory(file)
  end

  def linux_status_memory(file = nil)
    GetProcessMem::Os::Linux.new(pid).memory(file)
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
end
