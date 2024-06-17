module CodecLZOP

using CRC32
using LibLZO
using Printf
using SimpleChecksums
using TranscodingStreams

const _crc32 = CRC32.crc32

export LZOPCompressor, LZOPCompressorStream
export LZOPDecompressor, LZOPDecompressorStream

# re-export LZOP-supported LibLZO compressor types
export LZO1X, LZO1X_1, LZO1X_1_11, LZO1X_999

# re-export TranscodingStreams for ease of use
export TranscodingStreams

include("block.jl")
include("lzop_compressor.jl")
include("lzop_decompressor.jl")

end
