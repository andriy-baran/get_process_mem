class GetProcessMem
  class Bytes
    KB_TO_BYTE = BigDecimal(1024)          # 2**10   = 1024
    MB_TO_BYTE = BigDecimal(1_048_576)     # 1024**2 = 1_048_576
    GB_TO_BYTE = BigDecimal(1_073_741_824) # 1024**3 = 1_073_741_824
    CONVERSION = { "kb" => KB_TO_BYTE, "mb" => MB_TO_BYTE, "gb" => GB_TO_BYTE }

    def initialize(bytes)
      @bytes = bytes
    end

    def b
      @bytes
    end

    def kb
      (@bytes/KB_TO_BYTE).to_f
    end

    def mb
      (@bytes/MB_TO_BYTE).to_f
    end

    def gb
      (@bytes/GB_TO_BYTE).to_f
    end
  end
end
