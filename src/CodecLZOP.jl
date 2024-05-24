module CodecLZOP

using CRC32
using LibLZO
using Printf
using SimpleChecksums
using TranscodingStreams

const _crc32 = CRC32.crc32

include("block.jl")
include("lzop_compressor.jl")
include("lzop_decompressor.jl")

end
