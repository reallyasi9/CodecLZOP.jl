module CodecLZO

using LibLZO
using TranscodingStreams

include("block.jl")
include("lzop_compressor.jl")
include("lzop_decompressor.jl")

end
