
# TODO: add kwargs
struct LZOPDecompressor{A <: AbstractLZOAlgorithm, F<:Function} <: TranscodingStreams.Codec
    algo::A

    crc32::Bool
    filter_fun::F
    on_checksum_fail::Symbol

    LZOPDecompressor(algo::A = LZO1X_1(); crc32::Bool=true, filter=identity, on_checksum_fail::Symbol=:throw) where {A <: AbstractLZOAlgorithm} = new{A,typeof(filter)}(algo, crc32, filter, on_checksum_fail)
    
    LZOPDecompressor(::Type{A}; kwargs...) where {A <: AbstractLZOAlgorithm} = LZOPDecompressor(A(); kwargs...)
    
    function LZOPDecompressor(s::Symbol; kwargs...)
        A = LibLZO._SYMBOL_LOOKUP[s]
        return LZOPDecompressor(A; kwargs...)
    end
    
    LZOPDecompressor(s::String; kwargs...) = LZOPDecompressor(Symbol(s); kwargs...)
end

const LZOPDecompressorStream{A,S,F} = TranscodingStream{LZOPDecompressor{A,F}, S} where {A <: AbstractLZOAlgorithm, S <: IO, F<:Function}

function LZOPDecompressorStream(io::IO, algo::A = LZO1X_1(); kwargs...) where {A <: AbstractLZOAlgorithm}
    decompressor_kwargs, stream_kwargs = TranscodingStreams.splitkwargs(kwargs, (:crc32, :filter, :on_checksum_fail))
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

function TranscodingStreams.minoutsize(::LZOPDecompressor, input::TranscodingStreams.Memory)::Int64
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
        br, bw = decompress_block(input_io, output_io, codec.algo; crc32=codec.crc32, filter_function=codec.filter_fun, on_checksum_fail=codec.on_checksum_fail)
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