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
    
end

@testitem "LZOPCompressorStream constructors" begin
    
end

@testitem "LZOPDecompressorStream constructors" begin
    
end

@testitem "transcode round-trip random" begin

end

@testitem "transcode round-trip corpus" begin

end

@testitem "transcode round-trip pathological" begin

end

@run_package_tests verbose=true