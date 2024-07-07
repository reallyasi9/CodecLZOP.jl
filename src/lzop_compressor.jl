
"""
    LZOPCompressor([algo=LZO1X_1]; <keyword arguments>) <: TranscodingStreams.Codec

Compress data using the LZOP method.

# Arguments
- `algo`: `LibLZO.AbstractLZOAlgorithm`, `Type{LibLZO.AbstractLZOAlgorithm}`, `Symbol`, or `AbstractString` describing the LZO algorithm to use when compressing the data.

# Keyword Arguments
- `block_size::Integer = LZOP_DEFAULT_BLOCK_SIZE`: the maximum size of each block into which the input data will be split before compressing with LZO. Cannot be greater than `64 * 2^20` (64 MB).
- `uncompressed_checksum::Union{Symbol, Nothing} = :adler32`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the uncompressed data (default).
    - `:crc32`: write a CRC32 checksum of the uncompressed data.
    - `nothing`: do not write a checksum of the uncompressed data.
- `compressed_checksum::Union{Symbol, Nothing} = nothing`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the compressed data.
    - `:crc32`: write a CRC32 checksum of the compressed data.
    - `nothing`: do not write a checksum of the compressed data (default).
- `filter::Function = identity`: a function applied to the compressed data as it is streamed. The function must take a single `AbstractVector{UInt8}` argument and modify it in place without changing its size.
- `optimize::Bool = false`: whether to run the LZO optimization function on compressed data before writing it to the stream. Optimization doubles the compression time and rarely results in improved compression ratios, so it is disabled by default.

See also [`Codec`](@ref), [`AbstractLZOAlgorithm`](@ref).
"""
struct LZOPCompressor{A<:AbstractLZOAlgorithm,F<:Function} <: Codec
    algo::A

    block_size::Int
    uncompressed_checksum::Union{Symbol, Nothing}
    compressed_checksum::Union{Symbol, Nothing}
    filter_fun::F
    optimize::Bool

    function LZOPCompressor(algo::A = LZO1X_1(); block_size::Integer=LZOP_DEFAULT_BLOCK_SIZE, uncompressed_checksum::Union{Symbol, Nothing}=:adler32, compressed_checksum::Union{Symbol, Nothing}=nothing, filter=identity, optimize::Bool=false) where {A<:AbstractLZOAlgorithm}
        if !isnothing(uncompressed_checksum) && uncompressed_checksum ∉ (:adler32, :crc32)
            throw(ArgumentError("unexpected value for uncompressed_checksum: expected one of (:adler32, :crc32, nothing), got $uncompressed_checksum"))
        end
        if !isnothing(compressed_checksum) && compressed_checksum ∉ (:adler32, :crc32)
            throw(ArgumentError("unexpected value for compressed_checksum: expected one of (:adler32, :crc32, nothing), got $compressed_checksum"))
        end
        return new{A,typeof(filter)}(algo, block_size, uncompressed_checksum, compressed_checksum, filter, optimize)
    end

    function LZOPCompressor(::Type{A}; kwargs...) where {A<:AbstractLZOAlgorithm}
        compressor_kwargs, lzo_kwargs = splitkwargs(kwargs, (:block_size, :uncompressed_checksum, :compressed_checksum, :filter, :optimize))
        algo = A(; lzo_kwargs...)
        return LZOPCompressor(algo; compressor_kwargs...)
    end

    function LZOPCompressor(s::Symbol; kwargs...)
        A = _SYMBOL_LOOKUP[s]
        return LZOPCompressor(A; kwargs...)
    end

    function LZOPCompressor(s::AbstractString; kwargs...)
        return LZOPCompressor(Symbol(s); kwargs...)
    end
end

"""
    LZOPCompressorStream(io, [algo=LZO1X_1]; <keyword arguments>) <: TranscodingStreams.TranscodingStream

Compress stream using the LZOP method.

# Arguments
- `io::IO`: stream to compress.
- `algo`: `LibLZO.AbstractLZOAlgorithm`, `Type{LibLZO.AbstractLZOAlgorithm}`, `Symbol`, or `AbstractString` describing the LZO algorithm to use when compressing the data.

# Keyword Arguments
- `block_size::Integer = LZOP_DEFAULT_BLOCK_SIZE`: the maximum size of each block into which the input data will be split before compressing with LZO. Cannot be greater than `64 * 2^20` (64 MB).
- `uncompressed_checksum::Union{Symbol, Nothing} = :adler32`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the uncompressed data (default).
    - `:crc32`: write a CRC32 checksum of the uncompressed data.
    - `nothing`: do not write a checksum of the uncompressed data.
- `compressed_checksum::Union{Symbol, Nothing} = nothing`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the compressed data.
    - `:crc32`: write a CRC32 checksum of the compressed data.
    - `nothing`: do not write a checksum of the compressed data (default).
- `filter::Function = identity`: a function applied to the compressed data as it is streamed. The function must take a single `AbstractVector{UInt8}` argument and modify it in place without changing its size.
- `optimize::Bool = false`: whether to run the LZO optimization function on compressed data before writing it to the stream. Optimization doubles the compression time and rarely results in improved compression ratios, so it is disabled by default.

All other keyword arguments are passed unmodified to the `TranscodingStream` constructor.

See also [`TranscodingStream`](@ref), [`AbstractLZOAlgorithm`](@ref).
"""
const LZOPCompressorStream{A,S,F} = TranscodingStream{LZOPCompressor{A,F},S} where {A<:AbstractLZOAlgorithm,S<:IO,F<:Function}

function LZOPCompressorStream(io::IO, algo::A = LZO1X_1(); kwargs...) where {A<:AbstractLZOAlgorithm}
    compressor_kwargs, stream_kwargs = splitkwargs(kwargs, (:block_size, :uncompressed_checksum, :compressed_checksum, :filter, :optimize))
    return TranscodingStream(LZOPCompressor(algo; compressor_kwargs...), io; stream_kwargs...)
end

function LZOPCompressorStream(io::IO, ::Type{A}; kwargs...) where {A<:AbstractLZOAlgorithm}
    lzo_kwargs, other_kwargs = splitkwargs(kwargs, (:compression_level,))
    algo = A(; lzo_kwargs...)
    return LZOPCompressorStream(io, algo; other_kwargs...)
end

function LZOPCompressorStream(io::IO, s::Symbol; kwargs...)
    A = LibLZO._SYMBOL_LOOKUP[s]
    return LZOPCompressorStream(io, A; kwargs...)
end

LZOPCompressorStream(io::IO, s::AbstractString; kwargs...) = LZOPCompressorStream(io, Symbol(s); kwargs...)

function TranscodingStreams.minoutsize(codec::LZOPCompressor, input::Memory)::Int
    # Empty data compresses to a single, uncompressed length of UInt32(0)
    length(input) == 0 && return 4
    # Uncompressed length, compressed length: each a UInt32.
    # Uncompressed checksum, compressed checksum: each a UInt32.
    # You only get the compressed checksum if compressed length < uncompressed length.
    # And compressed length <= uncompressed length, always
    d = length(input) ÷ codec.block_size
    extra = 8 + (!isnothing(codec.uncompressed_checksum) ? 4 : 0) + (!isnothing(codec.compressed_checksum) ? 4 : 0)
    return length(input) + (d + 1) * extra
end

function TranscodingStreams.process(codec::LZOPCompressor, input::Memory, output::Memory, error::Error)
    r = zero(Int)
    w = zero(Int)

    # end of sequence
    if length(input) == 0
        # end of stream is UInt32(0)
        output[1] = 0x00
        output[2] = 0x00
        output[3] = 0x00
        output[4] = 0x00
        w += 4
        return (r, w, :end)
    end

    # output is guaranteed to be long enough to hold compressed input
    output_vec = unsafe_wrap(Vector{UInt8}, output.ptr, length(output))
    output_io = IOBuffer(output_vec; write=true, append=false, maxsize=length(output))
    while r < length(input)
        try
            n = min(codec.block_size, length(input) - r) % Int
            input_vec = unsafe_wrap(Vector{UInt8}, input.ptr + r, n)
            br, bw = compress_block(input_vec, output_io, codec.algo; uncompressed_checksum=codec.uncompressed_checksum, compressed_checksum=codec.compressed_checksum, filter_function=codec.filter_fun, optimize=codec.optimize)
            r += br
            w += bw
        catch e
            error[] = e
            return (r, w, :error)
        end
    end

    return (r, w, :ok)
end