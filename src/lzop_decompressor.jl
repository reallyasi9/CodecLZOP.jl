
"""
    LZOPDecompressor(algo; [compressed_checksum=:adler32, uncompressed_checksum=nothing filter=identity, on_checksum_fail=:throw]) <: TranscodingStreams.Codec

An implemention of the streaming decompression algorithm used by LZOP.

LZO ([Lempel-Ziv-Oberhumer](https://www.oberhumer.com/opensource/lzo/)) is a variant of the [LZ77 compression algorithm](https://doi.org/10.1109/TIT.1977.1055714). The original implementation of LZO (as implemented in liblzo2) can only compress and decompress entire blocks of in-memory data at once.

LZOP is a command-line utility that adds streaming compression and decompression capabilities to LZO by:
1. Splitting input data into blocks of fixed size; and
2. Adding header information to each block that contains compressed size, uncompressed size, and checksum information.

This codec implements the decompression of data in this format. Note that LZOP _archives_ (the output of the LZOP command-line utility) are concatenated collections of files compressed using the LZOP algorithm and contain additional header information for each file and cannot be decompressed directly using this codec.

# Arguments
- `algo`: an `LibLZO.AbstractLZOAlgorithm`, `Symbol`, or `AbstractString` describing the LZO algorithm to use when decompressing the data. The decompression algorithm must match the algorithm used to compress the data.

# Keyword Arguments
- `uncompressed_checksum::Union{Symbol, Nothing} = :adler32`: can be any of the following values:
    - `:adler32`: expect and decode an Adler32 checksum of the uncompressed data (default).
    - `:crc32`: expect and decode a CRC32 checksum of the uncompressed data.
    - `nothing`: expect no checksum of the uncompressed data.
- `compressed_checksum::Union{Symbol, Nothing} = nothing`: can be any of the following values:
    - `:adler32`: expect and decode an Adler32 checksum of the compressed data.
    - `:crc32`: expect and decode a CRC32 checksum of the compressed data.
    - `nothing`: expect no checksum of the compressed data (default).
- `filter::Function = identity`: a function applied to the decompressed data as it is streamed. The function must take a single `AbstractVector{UInt8}` argument and modify it in place without changing its size.
- `on_checksum_fail::Symbol = :throw`: a flag to determine how checksum failures are handled. `:throw` will cause an `ErrorException` to be thrown, `:warn` will log a warning using the `@warn` macro, and `:ignore` will silently ignore the failure.
"""
struct LZOPDecompressor{A <: AbstractLZOAlgorithm, F<:Function} <: TranscodingStreams.Codec
    algo::A

    uncompressed_checksum::Union{Symbol, Nothing}
    compressed_checksum::Union{Symbol, Nothing}
    filter_fun::F
    on_checksum_fail::Symbol

    function LZOPDecompressor(algo::A = LZO1X_1(); uncompressed_checksum::Union{Symbol, Nothing}=:adler32, compressed_checksum::Union{Symbol, Nothing}=nothing, filter=identity, on_checksum_fail::Symbol=:throw) where {A <: AbstractLZOAlgorithm}
        if !isnothing(uncompressed_checksum) && uncompressed_checksum ∉ (:adler32, :crc32)
            throw(ArgumentError("unexpected value for uncompressed_checksum: expected one of (:adler32, :crc32, nothing), got $uncompressed_checksum"))
        end
        if !isnothing(compressed_checksum) && compressed_checksum ∉ (:adler32, :crc32)
            throw(ArgumentError("unexpected value for compressed_checksum: expected one of (:adler32, :crc32, nothing), got $compressed_checksum"))
        end
        return new{A,typeof(filter)}(algo, uncompressed_checksum, compressed_checksum, filter, on_checksum_fail)
    end
    
    LZOPDecompressor(::Type{A}; kwargs...) where {A <: AbstractLZOAlgorithm} = LZOPDecompressor(A(); kwargs...)
    
    function LZOPDecompressor(s::Symbol; kwargs...)
        A = LibLZO._SYMBOL_LOOKUP[s]
        return LZOPDecompressor(A; kwargs...)
    end
    
    LZOPDecompressor(s::String; kwargs...) = LZOPDecompressor(Symbol(s); kwargs...)
end

const LZOPDecompressorStream{A,S,F} = TranscodingStream{LZOPDecompressor{A,F}, S} where {A <: AbstractLZOAlgorithm, S <: IO, F<:Function}

function LZOPDecompressorStream(io::IO, algo::A = LZO1X_1(); kwargs...) where {A <: AbstractLZOAlgorithm}
    decompressor_kwargs, stream_kwargs = TranscodingStreams.splitkwargs(kwargs, (:uncompressed_checksum, :compressed_checksum, :filter, :on_checksum_fail))
    return TranscodingStream(LZOPDecompressor(algo; decompressor_kwargs...), io; stream_kwargs...)
end

function LZOPDecompressorStream(io::IO, ::Type{A}; kwargs...) where {A <: AbstractLZOAlgorithm}
    lzo_kwargs, ts_kwargs = TranscodingStreams.splitkwargs(kwargs, (:compression_level,))
    algo = A(; lzo_kwargs...)
    return LZOPDecompressorStream(algo, io; ts_kwargs...)
end

function LZOPDecompressorStream(io::IO, s::Symbol; kwargs...)
    A = LibLZO._SYMBOL_LOOKUP[s]
    return LZOPDecompressorStream(io, A; kwargs...)
end

LZOPDecompressorStream(io::IO, s::AbstractString; kwargs...) = LZOPDecompressorStream(io, Symbol(s); kwargs...)

function TranscodingStreams.minoutsize(::LZOPDecompressor, input::TranscodingStreams.Memory)::Int
    # Because the codec decompresses by one block at a time, we can read off the size of the uncompressed data from the input directly (UInt32 in be order)
    length(input) < 4 && return 0
    return Int(input[1]) << 24 + Int(input[2]) << 16 + Int(input[3]) << 8 + Int(input[4])
end

function TranscodingStreams.process(codec::LZOPDecompressor, input::TranscodingStreams.Memory, output::TranscodingStreams.Memory, error::TranscodingStreams.Error)
    r = 0
    w = 0

    # end of sequence
    if length(input) == 0
        return (r, w, :end)
    end

    input_io = IOBuffer(unsafe_wrap(Vector{UInt8}, input.ptr, length(input)))
    # minoutsize guarantees this is large enough to hold the decompressed input
    output_io = IOBuffer(unsafe_wrap(Vector{UInt8}, output.ptr, length(output)); write=true, append=false, maxsize=length(output))
    try
        br, bw = decompress_block(input_io, output_io, codec.algo; uncompressed_checksum=codec.uncompressed_checksum, compressed_checksum=codec.compressed_checksum, filter_function=codec.filter_fun, on_checksum_fail=codec.on_checksum_fail)
        r += br
        w += bw
    catch e
        if !isa(e, EOFError) # EOFError just means we couldn't read the full block
            error[] = e
            return (r, w, :error)
        end
    end

    return (r, w, :ok)
end