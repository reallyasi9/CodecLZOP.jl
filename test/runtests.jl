using CodecLZOP
using Test
using TestItemRunner

@testitem "LZOPCompressor constructors" begin
    # default constructor
    c = LZOPCompressor()
    @test typeof(c) == LZOPCompressor{LZO1X_1,typeof(identity)}
    @test typeof(c.algo) == LZO1X_1
    @test c.block_size == CodecLZOP.LZOP_DEFAULT_BLOCK_SIZE
    @test c.crc32 == true
    @test c.filter_fun == identity
    @test c.optimize == false

    # kwarg constructor
    algo = LZO1X_1_11()
    block_size = 1
    crc32 = false
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, crc32=crc32, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.block_size == block_size
    @test c.crc32 == crc32
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo type constructor
    algo = LZO1X_1_11
    block_size = 1
    crc32 = false
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, crc32=crc32, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{algo,typeof(Base.:-)}
    @test typeof(c.algo) == algo
    @test c.block_size == block_size
    @test c.crc32 == crc32
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo symbol constructor
    algo = :LZO1X_1_11
    block_size = 1
    crc32 = false
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, crc32=crc32, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.block_size == block_size
    @test c.crc32 == crc32
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize

    # algo string constructor
    algo = "LZO1X_1_11"
    block_size = 1
    crc32 = false
    filter_fun = Base.:-
    optimize = true
    c = LZOPCompressor(algo; block_size=block_size, crc32=crc32, filter=filter_fun, optimize=optimize)
    @test typeof(c) == LZOPCompressor{LZO1X_1_11,typeof(Base.:-)}
    @test typeof(c.algo) == LZO1X_1_11
    @test c.block_size == block_size
    @test c.crc32 == crc32
    @test c.filter_fun == Base.:-
    @test c.optimize == optimize
end

@testitem "LZOPDecompressor constructors" begin
        # default constructor
        c = LZOPDecompressor()
        @test typeof(c) == LZOPDecompressor{LZO1X_1,typeof(identity)}
        @test typeof(c.algo) == LZO1X_1
        @test c.crc32 == true
        @test c.filter_fun == identity
        @test c.on_checksum_fail == :throw
    
        # kwarg constructor
        algo = LZO1X_1_11()
        crc32 = false
        filter_fun = Base.:-
        on_checksum_fail = :ignore
        c = LZOPDecompressor(algo; crc32=crc32, filter=filter_fun, on_checksum_fail=on_checksum_fail)
        @test typeof(c) == LZOPDecompressor{typeof(algo),typeof(Base.:-)}
        @test typeof(c.algo) == typeof(algo)
        @test c.crc32 == crc32
        @test c.filter_fun == Base.:-
        @test c.on_checksum_fail == on_checksum_fail
    
        # algo type constructor
        algo = LZO1X_1_11
        crc32 = false
        filter_fun = Base.:-
        on_checksum_fail = :ignore
        c = LZOPDecompressor(algo; crc32=crc32, filter=filter_fun, on_checksum_fail=on_checksum_fail)
        @test typeof(c) == LZOPDecompressor{algo,typeof(Base.:-)}
        @test typeof(c.algo) == algo
        @test c.crc32 == crc32
        @test c.filter_fun == Base.:-
        @test c.on_checksum_fail == on_checksum_fail
    
        # algo symbol constructor
        algo = :LZO1X_1_11
        crc32 = false
        filter_fun = Base.:-
        on_checksum_fail = :ignore
        c = LZOPDecompressor(algo; crc32=crc32, filter=filter_fun, on_checksum_fail=on_checksum_fail)
        @test typeof(c) == LZOPDecompressor{LZO1X_1_11,typeof(Base.:-)}
        @test typeof(c.algo) == LZO1X_1_11
        @test c.crc32 == crc32
        @test c.filter_fun == Base.:-
        @test c.on_checksum_fail == on_checksum_fail
    
        # algo string constructor
        algo = "LZO1X_1_11"
        crc32 = false
        filter_fun = Base.:-
        on_checksum_fail = :ignore
        c = LZOPDecompressor(algo; crc32=crc32, filter=filter_fun, on_checksum_fail=on_checksum_fail)
        @test typeof(c) == LZOPDecompressor{LZO1X_1_11,typeof(Base.:-)}
        @test typeof(c.algo) == LZO1X_1_11
        @test c.crc32 == crc32
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
    @test c.crc32 == true
    @test c.filter_fun == identity
    @test c.optimize == false

    # kwarg splitting constructor
    algo = LZO1X_1_11()
    block_size = 1
    crc32 = false
    filter_fun = Base.:-
    optimize = true
    bufsize = 2_000
    stop_on_end = true
    s = LZOPCompressorStream(io, algo; block_size=block_size, crc32=crc32, filter=filter_fun, optimize=optimize, bufsize=bufsize, stop_on_end=stop_on_end)
    c = s.codec
    @test s.stream == io
    @test typeof(c) == LZOPCompressor{typeof(algo),typeof(Base.:-)}
    @test typeof(c.algo) == typeof(algo)
    @test c.block_size == block_size
    @test c.crc32 == crc32
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
        @test c.crc32 == true
        @test c.filter_fun == identity
        @test c.on_checksum_fail == :throw
    
        # kwarg splitting constructor
        algo = LZO1X_1_11()
        block_size = 1
        crc32 = false
        filter_fun = Base.:-
        bufsize = 2_000
        on_checksum_fail = :ignore
        stop_on_end = true
        s = LZOPDecompressorStream(io, algo; crc32=crc32, filter=filter_fun, on_checksum_fail=on_checksum_fail, bufsize=bufsize, stop_on_end=stop_on_end)
        c = s.codec
        @test s.stream == io
        @test typeof(c) == LZOPDecompressor{typeof(algo),typeof(Base.:-)}
        @test typeof(c.algo) == typeof(algo)
        @test c.crc32 == crc32
        @test c.filter_fun == Base.:-
        @test c.on_checksum_fail == on_checksum_fail
        @test length(s.buffer1) == length(s.buffer2) == bufsize
        @test s.state.stop_on_end == stop_on_end
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

    data_io = IOBuffer(copy(data))
    cstream = LZOPCompressorStream(data_io)
    dcstream = LZOPDecompressorStream(cstream)
    decompressed = similar(data)
    readbytes!(dcstream, decompressed)
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

@testitem "transcode round-trip pathological" begin
    # unclear what, if any, pathological data would cause errors
end

@run_package_tests verbose=true