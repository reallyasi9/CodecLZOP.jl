
# TODO: add kwargs
@kwdef struct LZOPDecompressor{A <: AbstractLZOAlgorithm} <: Codec
    algo::A
    crc32::Bool = true
    filter_fun::F = identity
    on_checksum_fail::Symbol = :throw

    LZOPDecompressor(algo::A; kwargs...) where {A <: AbstractLZOAlgorithm} = new{A}(algo; kwargs...)
    
    LZOPDecompressor(::Type{A}; kwargs...) where {A <: AbstractLZOAlgorithm} = new{A}(A(; kwargs...))
    
    function LZOPDecompressor(algo::Symbol; kwargs...)
        T = LibLZO._SYMBOL_LOOKUP[algo]
        new{T}(T(kwargs...))
    end
    
    LZOPDecompressor(algo::String; kwargs...) = LZOPDecompressor(Symbol(algo); kwargs...)

    LZOPDecompressor{A}(; kwargs...) = new{A}(A(; kwargs...))

    LZOPDecompressor() = new{LZO1X_1}(LZO1X_1())
end

const LZOPDecompressorStream{A,S} = TranscodingStream{LZOPDecompressor{A}, S} where {A <: AbstractLZOAlgorithm, S <: IO}

function LZOPDecompressorStream(algo::A, io::IO; kwargs...) where {A <: AbstractLZOAlgorithm}
    return TranscodingStream(LZOPDecompressor(algo), io; kwargs...)
end

function LZOPDecompressorStream(::Type{A}, io::IO; kwargs...) where {A <: AbstractLZOAlgorithm}
    lzo_kwargs, ts_kwargs = TranscodingStreams.splitkwargs(kwargs, (:compression_level,))
    algo = A(; lzo_kwargs...)
    return LZOPDecompressorStream(algo, io; ts_kwargs...)
end

function LZOPDecompressorStream(algo::Symbol, io::IO; kwargs...)
    A = LibLZO._SYMBOL_LOOKUP[algo]
    return LZOPDecompressorStream(A, io; kwargs...)
end

LZOPDecompressorStream(algo::String, io::IO; kwargs...) = LZOPDecompressorStream(Symbol(algo), io; kwargs...)

function TranscodingStreams.minoutsize(::LZOPDeompressor, input::Memory)
    # Because the codec decompresses by one block at a time, we can read off the size of the uncompressed data from the input directly (UInt32 in be order)
    length(input) < 4 && return 0
    return Int(input[1]) << 24 + Int(input[2]) << 16 + Int(input[3]) << 8 + Int(input[4])
end

function TranscodingStreams.process(codec::LZOPDecompressor, input::Memory, output::Memory, error::Error)
    r = 0
    w = 0

    # end of sequence
    if length(input) == 0
        return (r, w, :end)
    end

    input_io = BufferIO(unsafe_wrap(Vector{UInt8}, input.ptr, length(input)))
    # minoutsize guarantees this is large enough to hold the decompressed input
    output_io = BufferIO(unsafe_wrap(Vector{UInt8}, output.ptr, length(output)); write=true)
    try
        br, bw = decompress_block(input_io, output_io, codec.algo; codec.crc32, codec.filter_fun, codec.on_checksum_fail)
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