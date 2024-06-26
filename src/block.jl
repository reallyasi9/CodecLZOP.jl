const LZOP_DEFAULT_BLOCK_SIZE = 256 * 1024
const LZOP_MAX_BLOCK_SIZE = 64 * 1024 * 1024

"""
    compress_block(input, output, algo; [kwargs...])::Tuple{Int,Int}

Compress a block of data from `input` to `output` using LZO algorithm `algo`, returning the number of bytes read from `input` and written to `output`.

# Arguments
- `input`: An `AbstractVector{UInt8}` or `IO` object containing the block of data to compress.
- `output::IO`: Output IO object to write the compressed block.

# Keyword arguments
- `block_size::Integer = LZOP_DEFAULT_BLOCK_SIZE`: Number of bytes to read from `input`. Will cap at `LZOP_MAX_BLOCK_SIZE`.
- `uncompressed_checksum::Union{Symbol, Nothing} = :adler32`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the uncompressed data (default).
    - `:crc32`: write a CRC32 checksum of the uncompressed data.
    - `nothing`: do not write a checksum of the uncompressed data.
- `compressed_checksum::Union{Symbol, Nothing} = nothing`: can be any of the following values:
    - `:adler32`: write an Adler32 checksum of the compressed data.
    - `:crc32`: write a CRC32 checksum of the compressed data.
    - `nothing`: do not write a checksum of the compressed data (default).
- `filter_function::Function = identity`: Transform the input data using the specified filter functions. The filter function must accept a single `AbstractVector{UInt8}` argument and must modify that vector in-place.
- `optimize::Bool = false`: If `true`, process the data twice to optimize how it is stored for faster decompression. Setting this to `true` doubles compression time with little to no improvement in decompression time, so its use is not recommended.
"""
function compress_block(invec::AbstractVector{UInt8}, output::IO, algo::AbstractLZOAlgorithm; block_size::Integer=LZOP_DEFAULT_BLOCK_SIZE, uncompressed_checksum::Union{Symbol, Nothing}=:adler32, compressed_checksum::Union{Symbol, Nothing}=nothing, filter_function::F=identity, optimize::Bool=false) where {F <: Function}
    (isnothing(uncompressed_checksum) || uncompressed_checksum ∈ (:crc32, :adler32)) || throw(ArgumentError("unexpected uncompressed checksum value: $uncompressed_checksum"))
    (isnothing(compressed_checksum) || compressed_checksum ∈ (:crc32, :adler32)) || throw(ArgumentError("unexpected compressed checksum value: $compressed_checksum"))

    block_size > LZOP_MAX_BLOCK_SIZE && @warn "block size clamped at maximum LZOP block size" block_size LZOP_MAX_BLOCK_SIZE
    bytes_read = min(length(invec), block_size, LZOP_MAX_BLOCK_SIZE) % Int

    bytes_written = zero(Int)

    # uncompressed length
    bytes_written += write(output, hton(bytes_read % UInt32))

    # final block has length of 0 and signals end of stream
    if bytes_read == 0 
        return bytes_read, bytes_written
    end

    # Use a view into the data from here on out, making sure to accomodate for things like OffsetArrays
    input = @view invec[begin:begin+bytes_read-1]

    # uncompressed checksum
    if isnothing(uncompressed_checksum)
        checksum = UInt32(0)
    elseif uncompressed_checksum == :crc32
        checksum = _crc32(input)
    else
        checksum = adler32(input)
    end

    # filter after checksum is calculated
    filter_function(input)

    # compressed length
    compressed = compress(algo, input)
    compressed_length = min(bytes_read, length(compressed)) % UInt32

    bytes_written += write(output, hton(compressed_length))
    if !isnothing(uncompressed_checksum)
        bytes_written += write(output, hton(checksum))
    end

    # optimize only if using compressed data
    use_compressed = length(compressed) < bytes_read
    if optimize && use_compressed
        original_length = unsafe_optimize!(algo, input, compressed)
        if original_length != bytes_read
            throw(ErrorException("LZO optimization failed"))
        end
    end

    # compressed checksum is only output if compression is used
    if use_compressed
        if !isnothing(compressed_checksum)
            if compressed_checksum == :crc32
                checksum = _crc32(input)
            else
                checksum = adler32(input)
            end
            bytes_written += write(output, hton(checksum))
        end
        bytes_written += write(output, compressed)
    else
        bytes_written += write(output, input)
    end

    return bytes_read, bytes_written
end

# Extract data to a Vector if the input is a generic IO object.
function compress_block(io::IO, output::IO, algo::AbstractLZOAlgorithm; kwargs...)
    input = Vector{UInt8}()
    readbytes!(io, input, LZOP_MAX_BLOCK_SIZE)
    return compress_block(input, output, algo; kwargs...)
end

# Avoid the extra copy and use the buffer directly if the input is already an IOBuffer object.
function compress_block(io::IOBuffer, output::IO, algo::AbstractLZOAlgorithm; kwargs...)
    last_byte = min(io.size - io.ptr + 1, LZOP_MAX_BLOCK_SIZE)
    input = @view io.data[io.ptr:last_byte]
    return compress_block(input, output, algo; kwargs...)
end

compress_block(input::AbstractString, output::IO, algo::AbstractLZOAlgorithm; kwargs...) = compress_block(codeunits(input), output, algo; kwargs...)


"""
    decompress_block(input, output, algo; [kwargs...])::Tuple{Int,Int}

Decompress a block of data from `input` to `output` using LZO algorithm `algo`, returning the number of bytes read from `input` and written to `output`.

# Arguments
- `input`: An `AbstractVector{UInt8}` or `IO` object containing the block of LZO-compressed data to decompress.
- `output::IO`: Output IO object to write the decompressed block.

# Keyword arguments
- `uncompressed_checksum::Union{Symbol, Nothing} = :adler32`: can be any of the following values:
    - `:adler32`: expect and decode an Adler32 checksum of the uncompressed data (default).
    - `:crc32`: expect and decode a CRC32 checksum of the uncompressed data.
    - `nothing`: expect no checksum of the uncompressed data.
- `compressed_checksum::Union{Symbol, Nothing} = nothing`: can be any of the following values:
    - `:adler32`: expect and decode an Adler32 checksum of the compressed data.
    - `:crc32`: expect and decode a CRC32 checksum of the compressed data.
    - `nothing`: expect no checksum of the compressed data (default).
- `filter_function::Function = identity`: Untransform the output data using the specified filter function. The filter function must take a single `AbstractVector{UInt8}` argument and modify it in place.
- `on_checksum_fail::Symbol = :throw`: Choose how the function responds to invalud checksums. If `:throw`, an `ErrorException` will be thrown. If `:warn`, a warning will be printed. If `:ignore`, the checksum values will be completely ignored.
"""
function decompress_block(input::IO, output::IO, algo::AbstractLZOAlgorithm; uncompressed_checksum::Union{Symbol, Nothing}=:adler32, compressed_checksum::Union{Symbol, Nothing}=nothing, filter_function::F=identity, on_checksum_fail::Symbol=:throw) where {F <: Function}
    on_checksum_fail ∉ (:throw, :warn, :ignore) && throw(ArgumentError("on_checksum_fail must be one of :throw, :warn, or :ignore (got $on_checksum_fail)"))
    (isnothing(uncompressed_checksum) || uncompressed_checksum ∈ (:crc32, :adler32)) || throw(ArgumentError("unexpected uncompressed checksum value: $uncompressed_checksum"))
    (isnothing(compressed_checksum) || compressed_checksum ∈ (:crc32, :adler32)) || throw(ArgumentError("unexpected compressed checksum value: $compressed_checksum"))

    # uncompressed length
    uncompressed_length = ntoh(read(input, UInt32))
    bytes_read = Int(4)
    bytes_written = zero(Int)

    # abort if uncompressed length is zero
    if uncompressed_length == 0
        return bytes_read, bytes_written
    end

    # error if uncompressed length is too long, irrespective of checksum fail flag
    uncompressed_length > LZOP_MAX_BLOCK_SIZE && throw(ErrorException("invalid LZOP block: uncompressed length greater than max block size ($uncompressed_length > $LZOP_MAX_BLOCK_SIZE)"))

    # compressed length
    compressed_length = ntoh(read(input, UInt32))
    bytes_read += 4

    # error if larger than uncompressed length, irrespective of checksum fail flag
    compressed_length > uncompressed_length && throw(ErrorException("invalid LZOP block: uncompressed length less than compressed length ($uncompressed_length < $compressed_length)"))

    uchecksum = UInt32(0)
    if !isnothing(uncompressed_checksum)
        uchecksum = ntoh(read(input, UInt32))
        bytes_read += 4
    end

    # only read compressed checksum if it is expected and the data are compressed
    cchecksum = UInt32(0)
    if !isnothing(compressed_checksum) && compressed_length < uncompressed_length
        cchecksum = ntoh(read(input, UInt32))
        bytes_read += 4
    end

    # use raw data if compressed and uncompressed lengths are the same
    raw_data = Vector{UInt8}(undef, compressed_length)
    readbytes!(input, raw_data, compressed_length)
    bytes_read += compressed_length

    if !isnothing(compressed_checksum) && on_checksum_fail != :ignore
        computed_cc = (compressed_checksum == :crc32) ? _crc32(raw_data) : adler32(raw_data)
        if computed_cc != cchecksum
            if on_checksum_fail == :throw
                throw(ErrorException("invalid LZOP block: compressed checksum recorded in block does not equal computed checksum of type $compressed_checksum ($(@sprintf("%08x", cchecksum)) != $(@sprintf("%08x", computed_cc)))"))
            elseif on_checksum_fail == :warn
                @warn "invalid LZOP block: compressed checksum recorded in block does not equal computed checksum" compressed_checksum recorded_checksum = cchecksum computed_checksum = computed_cc
            end
        end
    end

    if compressed_length < uncompressed_length
        uncompressed_data = Vector{UInt8}(undef, uncompressed_length)
        decompressed_length = unsafe_decompress!(algo, uncompressed_data, raw_data)
        decompressed_length != uncompressed_length && throw(ErrorException("invalid LZOP block: uncompressed length recorded in block does not equal length of decompressed data reported by LZO algorithm: ($uncompressed_length != $decompressed_length)"))
    else
        uncompressed_data = raw_data
    end

    # in-place unfilter of data before the checksum
    filter_function(uncompressed_data)

    # only perform final checksum if flag not set to ignore and the data is compressed
    if !isnothing(uncompressed_checksum) && compressed_length < uncompressed_length && on_checksum_fail != :ignore
        computed_uc = (uncompressed_checksum == :crc32) ? _crc32(uncompressed_data) : adler32(uncompressed_data)
        if computed_uc != uchecksum
            if on_checksum_fail == :throw
                throw(ErrorException("invalid LZOP block: uncompressed checksum recorded in block does not equal computed checksum of type $uncompressed_checksum ($(@sprintf("%08x", uchecksum)) != $(@sprintf("%08x", computed_uc)))"))
            elseif on_checksum_fail == :warn
                @warn "invalid LZOP block: uncompressed checksum recorded in block does not equal computed checksum" uncompressed_checksum recorded_checksum = uchecksum computed_checksum = computed_uc
            end
        end
    end

    bytes_written = write(output, uncompressed_data)

    return bytes_read, bytes_written
end

# Wrap data in an IOBuffer if input is a Vector of bytes
function decompress_block(input::AbstractVector{UInt8}, output::IO, algo::AbstractLZOAlgorithm; kwargs...)
    io = IOBuffer(input)
    return decompress_block(io, output, algo; kwargs...)
end
