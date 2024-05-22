# TODO: Fix kwargs
@kwdef struct LZOPCompressor{A <: AbstractLZOAlgorithm, F <: Function} <: Codec
    algo::A
    buffer::Vector{UInt8}

    block_size::Int = LZOP_DEFAULT_BLOCK_SIZE
    crc32::Bool = true
    filter_fun::F = identity
    optimize::Bool = false

    LZOPCompressor(algo::A; crc32::Bool = true, filter_fun = identity, optimize::Bool = false) where {A <: AbstractLZOAlgorithm} = new{A}(algo, UInt8[], crc32, filter_fun, optimize)
    
    function LZOPCompressor(::Type{A}; kwargs...) where {A <: AbstractLZOAlgorithm}
        compressor_kwargs, lzo_kwargs = TranscodingStreams.splitkwargs(kwargs, (:crc32, :filter_fun, :optimize))
        new{A}(A(; lzo_kwargs...), UInt8[]; compressor_kwargs...)
    end
    
    function LZOPCompressor(algo::Symbol; kwargs...)
        T = LibLZO._SYMBOL_LOOKUP[algo]
        compressor_kwargs, lzo_kwargs = TranscodingStreams.splitkwargs(kwargs, (:crc32, :filter_fun, :optimize))
        new{T}(T(; lzo_kwargs...), UInt8[]; compressor_kwargs...)
    end
    
    LZOPCompressor(algo::String; kwargs...) = LZOPCompressor(Symbol(algo); kwargs...)

    function LZOPCompressor{A}(; kwargs...)
        compressor_kwargs, lzo_kwargs = TranscodingStreams.splitkwargs(kwargs, (:crc32, :filter_fun, :optimize))
        new{A}(A(; lzo_kwargs...), UInt8[]; compressor_kwargs...)
    end

    LZOPCompressor(; kwargs...) = new{LZO1X_1}(LZO1X_1(), UInt8[]; kwargs...)
end

const LZOPCompressorStream{A,S} = TranscodingStream{LZOPCompressor{A}, S} where {A <: AbstractLZOAlgorithm, S <: IO}

function LZOPCompressorStream(algo::A, io::IO; kwargs...) where {A <: AbstractLZOAlgorithm}
    return TranscodingStream(LZOPCompressor(algo), io; kwargs...)
end

function LZOPCompressorStream(::Type{A}, io::IO; kwargs...) where {A <: AbstractLZOAlgorithm}
    lzo_kwargs, ts_kwargs = TranscodingStreams.splitkwargs(kwargs, (:compression_level,))
    algo = A(; lzo_kwargs...)
    return LZOPCompressorStream(algo, io; ts_kwargs...)
end

function LZOPCompressorStream(algo::Symbol, io::IO; kwargs...)
    A = LibLZO._SYMBOL_LOOKUP[algo]
    return LZOPCompressorStream(A, io; kwargs...)
end

LZOPCompressorStream(algo::String, io::IO; kwargs...) = LZOPCompressorStream(Symbol(algo), io; kwargs...)

function TranscodingStreams.minoutsize(codec::LZOPCompressor, input::Memory)
    # Empty data compresses to a single, uncompressed length of UInt32(0)
    length(input) == 0 && return 4
    # Uncompressed length, uncompressed checksum, compressed length, and compressed checksum: each a UInt32.
    # You only get the compressed checksum if compressed length < uncompressed length.
    # And compressed length <= uncompressed length, always
    # Thus the maximum number of bytes occurs when each input block compresses by exactly one byte, thereby increasing the total size by 11 bytes per block.
    d = length(input) ÷ codec.block_size
    return length(input) + (d + 1) * 11
end

function TranscodingStreams.process(codec::LZOPCompressor, input::Memory, output::Memory, error::Error)
    r = 0
    w = 0

    # output first
    if !isempty(codec.buffer)
        n = min(length(codec.buffer), length(output) % Int)
        unsafe_copyto!(output.ptr, pointer(codec.buffer), n)
        deleteat!(codec.buffer, 1:n)
        w += n
    end

    # end of sequence
    if length(input) == 0
        status = isempty(codec.buffer) ? :end : :ok
        return (0, w, status)
    end

    output_io = BufferIO(codec.buffer; append=true)
    while length(input) - r >= LZOP_MAX_BLOCK_SIZE
        try
            n = min(LZOP_MAX_BLOCK_SIZE, length(input) - r)
            input_vec = unsafe_wrap(Vector{UInt8}, input.ptr + r, n)
            br, _ = compress_block(input_vec, output_io, codec.algo; codec.crc32, codec.filter_fun, codec.optimize)
            r += br
        catch e
            error[] = e
            return (r, w, :error)
        end
    end

    return (r, w, :ok)
end