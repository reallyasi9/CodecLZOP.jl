module CodecLZOP

using CRC32: CRC32
using LibLZO: AbstractLZOAlgorithm, LZO1X, LZO1X_1, LZO1X_1_11, LZO1X_999, compress, decompress!, unsafe_optimize!, _SYMBOL_LOOKUP
using Printf: @sprintf
using SimpleChecksums: SimpleChecksums
using TranscodingStreams: TranscodingStreams, TranscodingStream, Codec, Memory, Error, splitkwargs

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
