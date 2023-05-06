class GetProcessMem
  module OsDetector
    def self.runs_on_darwin?
      Gem.platforms.detect do |p|
        p.is_a?(Gem::Platform) && p.os == 'darwin'
      end
    end

    def self.runs_on_windows?
      Gem.win_platform?
    end
  end
end
