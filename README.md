# CodecLZOP

An implementation of the streaming [LZO compression and decompression](https://github.com/reallyasi9/LibLZO.jl) format used in the [LZOP command line utility](https://www.lzop.org/) as a Codec for [TranscodingStreams.jl](https://github.com/JulioIO/TranscodingStreams.jl).

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://reallyasi9.github.io/CodecLZOP.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://reallyasi9.github.io/CodecLZOP.jl/dev/)
[![Dev Build Status](https://github.com/reallyasi9/CodecLZOP.jl/actions/workflows/Test.yml/badge.svg?branch=development)](https://github.com/reallyasi9/CodecLZOP.jl/actions/workflows/Test.yml?query=branch%3Adevelopment)

## Installation

```julia
Pkg.add("CodecLZOP")
```

## Usage

```julia
using CodecLZOP

# Some text.
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sollicitudin
mauris non nisi consectetur, a dapibus urna pretium. Vestibulum non posuere
erat. Donec luctus a turpis eget aliquet. Cras tristique iaculis ex, eu
malesuada sem interdum sed. Vestibulum ante ipsum primis in faucibus orci luctus
et ultrices posuere cubilia Curae; Etiam volutpat, risus nec gravida ultricies,
erat ex bibendum ipsum, sed varius ipsum ipsum vitae dui.
"""

# Streaming API.
stream = LZOPCompressorStream(IOBuffer(text))
for line in eachline(LZOPDecompressorStream(stream))
    println(line)
end
close(stream)

# Array API.
compressed = transcode(LZOPCompressor, text)
@assert sizeof(compressed) < sizeof(text)
@assert transcode(LZOPDecompressor, compressed) == Vector{UInt8}(text)
```

This package exports following codecs and streams:

| Codec                  | Stream                       |
| ---------------------- | ---------------------------- |
| `LZOPCompressor`       | `LZOPCompressorStream`       |
| `LZOPDecompressor`     | `LZOPDecompressorStream`     |

See docstrings and [TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl) for details.

## Note about LZO and LZOP

LZO ([Lempel-Ziv-Oberhumer](https://www.oberhumer.com/opensource/lzo/)) is a variant of the [LZ77 compression algorithm](https://doi.org/10.1109/TIT.1977.1055714). The implementation of LZO in liblzo2 can only compress and decompress entire blocks of data in memory and all at once. [LZOP](https://www.lzop.org/) is a command-line utility that implements streaming compression and decompression capabilities using LZO by:

1. Splitting input data into independent blocks; and
2. Adds information at the beginning of each block that encodes compressed size, uncompressed size, and checksum information.

This codec implements streaming compression and decompression of data by implementing the method of LZOP. Note that LZOP _archives_ (the files produced by the LZOP command-line utility) are concatenated collections of files compressed using the LZOP method, but these archives contain additional header information for each file and therefore `CodecLZOP` will _not_ directly encode or decode these files. For a Julia utility that reads and writes LZOP archives, see the documentation for [LZOPStreams.jl](https://github.com/reallyasi9/LZOPStreams.jl).
