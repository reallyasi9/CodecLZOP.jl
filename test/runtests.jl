using CodecLZOP
using Test
using TestItemRunner

@testitem "LZOPCompressor constructors" begin
    # default constructor
    c = LZOPCompressor()
    @test typeof(c) == LZOPCompressor{LZO1X_1,typeof(identity)}
    @test typeof(c.algo) == LZO1X_1
    @test c.block_size == CodecLZOP.LZOP_DEFAULT_BLOCK_SIZE
    @test c.uncompressed_checksum == :adler32
    @test isnothing(c.compressed_checksum)
    @test c.filter_fun == identity
    @test c.optimize == false

    # kwarg constructor
    algo = LZO1X_1_11()
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.block_size == block_size
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo type constructor
    algo = LZO1X_1_11
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{algo,typeof(Base.:-)}
    @test typeof(c.algo) == algo
    @test c.block_size == block_size
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo symbol constructor
    algo = :LZO1X_1_11
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.block_size == block_size
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo string constructor
    algo = "LZO1X_1_11"
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.block_size == block_size
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize
end

@testitem "LZOPDecompressor constructors" begin
    # default constructor
    c = LZOPDecompressor()
    @test typeof(c) == LZOPDecompressor{LZO1X_1,typeof(identity)}
    @test typeof(c.algo) == LZO1X_1
    @test c.uncompressed_checksum == :adler32
    @test isnothing(c.compressed_checksum)
    @test c.filter_fun == identity
    @test c.on_checksum_fail == :throw

    # kwarg constructor
    algo = LZO1X_1_11()
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    on_checksum_fail = :ignore
    c = LZOPDecompressor(algo; uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, on_checksum_fail=on_checksum_fail)
    @test typeof(c) == LZOPDecompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.on_checksum_fail == on_checksum_fail

    # algo type constructor
    algo = LZO1X_1_11
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    on_checksum_fail = :ignore
    c = LZOPDecompressor(algo; uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, on_checksum_fail=on_checksum_fail)
    @test typeof(c) == LZOPDecompressor{algo,typeof(Base.:-)}
    @test typeof(c.algo) == algo
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.on_checksum_fail == on_checksum_fail

    # algo symbol constructor
    algo = :LZO1X_1_11
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    on_checksum_fail = :ignore
    c = LZOPDecompressor(algo; uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, on_checksum_fail=on_checksum_fail)
    @test typeof(c) == LZOPDecompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.on_checksum_fail == on_checksum_fail

    # algo string constructor
    algo = "LZO1X_1_11"
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    on_checksum_fail = :ignore
    c = LZOPDecompressor(algo; uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, on_checksum_fail=on_checksum_fail)
    @test typeof(c) == LZOPDecompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.on_checksum_fail == on_checksum_fail
end

@testitem "LZOPCompressorStream constructors" begin
    # default constructor
    io = IOBuffer()
    s = LZOPCompressorStream(io)
    c = s.codec
    @test s.stream == io
    @test typeof(c) == LZOPCompressor{LZO1X_1,typeof(identity)}
    @test typeof(c.algo) == LZO1X_1
    @test c.block_size == CodecLZOP.LZOP_DEFAULT_BLOCK_SIZE
    @test c.uncompressed_checksum == :adler32
    @test isnothing(c.compressed_checksum)
    @test c.filter_fun == identity
    @test c.optimize == false

    # kwarg splitting constructor
    algo = LZO1X_1_11()
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    optimize = true
    bufsize = 2_000
    stop_on_end = true
    s = LZOPCompressorStream(io, algo; block_size=block_size, uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, optimize=optimize, bufsize=bufsize, stop_on_end=stop_on_end)
    c = s.codec
    @test s.stream == io
    @test typeof(c) == LZOPCompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.block_size == block_size
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize
    @test length(s.buffer1) == length(s.buffer2) == bufsize
    @test s.state.stop_on_end == stop_on_end
end

@testitem "LZOPDecompressorStream constructors" begin
    # default constructor
    io = IOBuffer()
    s = LZOPDecompressorStream(io)
    c = s.codec
    @test s.stream == io
    @test typeof(c) == LZOPDecompressor{LZO1X_1,typeof(identity)}
    @test typeof(c.algo) == LZO1X_1
    @test c.uncompressed_checksum == :adler32
    @test isnothing(c.compressed_checksum)
    @test c.filter_fun == identity
    @test c.on_checksum_fail == :throw

    # kwarg splitting constructor
    algo = LZO1X_1_11()
    block_size = 1
    uncompressed_checksum = nothing
    compressed_checksum = :crc32
    filter_fun = Base.:-
    bufsize = 2_000
    on_checksum_fail = :ignore
    stop_on_end = true
    s = LZOPDecompressorStream(io, algo; uncompressed_checksum=uncompressed_checksum, compressed_checksum=compressed_checksum, filter=filter_fun, on_checksum_fail=on_checksum_fail, bufsize=bufsize, stop_on_end=stop_on_end)
    c = s.codec
    @test s.stream == io
    @test typeof(c) == LZOPDecompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.uncompressed_checksum == uncompressed_checksum
    @test c.compressed_checksum == compressed_checksum
    @test c.filter_fun == Base.:-
    @test c.on_checksum_fail == on_checksum_fail
    @test length(s.buffer1) == length(s.buffer2) == bufsize
    @test s.state.stop_on_end == stop_on_end
end

@testitem "stream round-trip random" begin
    using Random
    
    rng = Random.MersenneTwister(42)
    data = rand(rng, UInt8, 1_000_000)
    
    data_io = IOBuffer(copy(data))
    cstream = LZOPCompressorStream(data_io)
    dcstream = LZOPDecompressorStream(cstream)
    decompressed = similar(data)
    readbytes!(dcstream, decompressed)
    @test decompressed == data
end

@testitem "transcode round-trip random" begin
    using Random
    using TranscodingStreams

    rng = Random.MersenneTwister(42)
    data = rand(rng, UInt8, 1_000_000)

    compressed = transcode(LZOPCompressor, data)
    @test compressed != data
    @test length(compressed) >= length(data) # random data does not compress
    decompressed = transcode(LZOPDecompressor, compressed)
    @test decompressed == data
end

@testitem "transcode round-trip corpus" begin
    using LazyArtifacts
    using LibLZO
    using Random
    using TranscodingStreams

    let
        algos = (
            LZO1X_1, LZO1X_1_11, LZO1X_1_12, LZO1X_1_15, LZO1X_999,
            LZO1, LZO1_99,
            LZO1A, LZO1A_99,
            LZO1B, LZO1B_99,
            LZO1C, LZO1C_99, LZO1C_999,
            LZO1F_1, LZO1F_999,
            LZO1Y_1, LZO1Y_999,
            LZO1Z_999,
            LZO2A_999,
        )
        cc_path = artifact"CanterburyCorpus"
        for fn in readdir(cc_path; sort=true, join=true)
            truth = read(fn)
            for algo in algos
                compressed = transcode(LZOPCompressor, truth)
                @test compressed != truth
                @test length(compressed) <= length(truth)
                decompressed = transcode(LZOPDecompressor, compressed)
                @test decompressed == truth

                data_io = IOBuffer(copy(truth))
                cstream = LZOPCompressorStream(data_io)
                dcstream = LZOPDecompressorStream(cstream)
                decompressed = similar(truth)
                readbytes!(dcstream, decompressed)
                @test decompressed == truth
            end
        end
    end
end

@testitem "mismatched compression algorithms" begin
    using LazyArtifacts
    using LibLZO
    using TranscodingStreams

    let 
        cc_path = artifact"CanterburyCorpus"
        fn = first(readdir(cc_path; sort=true, join=true))
        truth = read(fn)

        compressed = transcode(LZOPCompressor(LZO1X_1), truth)
        @test_throws Exception transcode(LZOPDecompressor(LZO1Z_999), compressed)
    end
end

@testitem "bad checksum options" begin
    using TranscodingStreams

    test_data = Vector{UInt8}("Hello, Julia!"^10)
    
    compressed = transcode(LZOPCompressor(; uncompressed_checksum=:adler32, compressed_checksum=:crc32), test_data)

    # note: writing a checksum and skipping the check for it might result in a hard crash, so DO NOT DO THAT!
    @test_throws Exception transcode(LZOPDecompressor(; uncompressed_checksum=:crc32, compressed_checksum=:crc32), compressed)
    @test_throws Exception transcode(LZOPDecompressor(; uncompressed_checksum=:adler32, compressed_checksum=:adler32), compressed)

    # bytes 12:15 are the uncompressed checksum 16:19 the compressed checksum
    bad_uncompressed = copy(compressed)
    bad_uncompressed[12] = bad_uncompressed[12]+1
    @test_throws Exception transcode(LZOPDecompressor(; uncompressed_checksum=:adler32, compressed_checksum=:crc32), bad_uncompressed)

    bad_compressed = copy(compressed)
    bad_compressed[16] = bad_compressed[16]+1
    @test_throws Exception transcode(LZOPDecompressor(; uncompressed_checksum=:adler32, compressed_checksum=:crc32), bad_compressed)
    
end

@testitem "bad block sizes" begin
    using TranscodingStreams

    test_data = Vector{UInt8}("Hello, Julia!"^10)

    compressed = transcode(LZOPCompressor, test_data)

    # bytes 1:4 are the uncompressed size
    bad_uncompressed = copy(compressed)
    bad_uncompressed[4] = bad_uncompressed[4]-1
    @test_throws Exception transcode(LZOPDecompressor, bad_uncompressed)

    # bytes 5:8 are the compressed size
    bad_compressed = copy(compressed)
    bad_compressed[8] = bad_compressed[8]-1
    @test_throws Exception transcode(LZOPDecompressor, bad_compressed)
end

@run_package_tests verbose=true