# TODO: Fix kwargs
struct LZOPCompressor{A<:AbstractLZOAlgorithm,F<:Function} <: TranscodingStreams.Codec
    algo::A

    block_size::Int
    crc32::Bool
    filter_fun::F
    optimize::Bool

    function LZOPCompressor(algo::A = LZO1X_1(); block_size::Integer=LZOP_DEFAULT_BLOCK_SIZE, crc32::Bool=true, filter=identity, optimize::Bool=false) where {A<:AbstractLZOAlgorithm}
        return new{A,typeof(filter)}(algo, block_size, crc32, filter, optimize)
    end

    function LZOPCompressor(::Type{A}; kwargs...) where {A<:AbstractLZOAlgorithm}
        compressor_kwargs, lzo_kwargs = TranscodingStreams.splitkwargs(kwargs, (:block_size, :crc32, :filter, :optimize))
        algo = A(; lzo_kwargs...)
        return LZOPCompressor(algo; compressor_kwargs...)
    end

    function LZOPCompressor(s::Symbol; kwargs...)
        A = LibLZO._SYMBOL_LOOKUP[s]
        return LZOPCompressor(A; kwargs...)
    end

    function LZOPCompressor(s::AbstractString; kwargs...)
        return LZOPCompressor(Symbol(s); kwargs...)
    end
end

const LZOPCompressorStream{A,S,F} = TranscodingStream{LZOPCompressor{A,F},S} where {A<:AbstractLZOAlgorithm,S<:IO,F<:Function}

function LZOPCompressorStream(io::IO, algo::A = LZO1X_1(); kwargs...) where {A<:AbstractLZOAlgorithm}
    compressor_kwargs, stream_kwargs = TranscodingStreams.splitkwargs(kwargs, (:block_size, :crc32, :filter, :optimize))
    return TranscodingStream(LZOPCompressor(algo; compressor_kwargs...), io; stream_kwargs...)
end

function LZOPCompressorStream(io::IO, ::Type{A}; kwargs...) where {A<:AbstractLZOAlgorithm}
    lzo_kwargs, other_kwargs = TranscodingStreams.splitkwargs(kwargs, (:compression_level,))
    algo = A(; lzo_kwargs...)
    return LZOPCompressorStream(io, algo; other_kwargs...)
end

function LZOPCompressorStream(io::IO, s::Symbol; kwargs...)
    A = LibLZO._SYMBOL_LOOKUP[s]
    return LZOPCompressorStream(io, A; kwargs...)
end

LZOPCompressorStream(io::IO, s::AbstractString; kwargs...) = LZOPCompressorStream(io, Symbol(s); kwargs...)

function TranscodingStreams.minoutsize(codec::LZOPCompressor, input::TranscodingStreams.Memory)::Int
    # Empty data compresses to a single, uncompressed length of UInt32(0)
    length(input) == 0 && return 4
    # Uncompressed length, compressed length, uncompressed checksum, and compressed checksum: each a UInt32.
    # You only get the compressed checksum if compressed length < uncompressed length.
    # And compressed length <= uncompressed length, always
    # Thus the maximum number of bytes occurs when each input block compresses by exactly one byte, thereby increasing the total size by 15 bytes per block.
    d = length(input) ÷ codec.block_size
    return length(input) + (d + 1) * 15
end

function TranscodingStreams.process(codec::LZOPCompressor, input::TranscodingStreams.Memory, output::TranscodingStreams.Memory, error::TranscodingStreams.Error)
    r = 0
    w = 0

    # end of sequence
    if length(input) == 0
        # end of stream is UInt32(0)
        output[1] = 0x00
        output[2] = 0x00
        output[3] = 0x00
        output[4] = 0x00
        return (0, 4, :end)
    end

    # output is guaranteed to be long enough to hold compressed input
    output_vec = unsafe_wrap(Vector{UInt8}, output.ptr, length(output))
    output_io = IOBuffer(output_vec; write=true, append=false, maxsize=length(output))
    while r < length(input)
        try
            n = min(codec.block_size, length(input) - r) % Int
            input_vec = unsafe_wrap(Vector{UInt8}, input.ptr + r, n)
            br, bw = compress_block(input_vec, output_io, codec.algo; crc32=codec.crc32, filter_function=codec.filter_fun, optimize=codec.optimize)
            r += br
            w += bw
        catch e
            error[] = e
            return (r, w, :error)
        end
    end

    return (r, w, :ok)
end