var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = CodecLZO","category":"page"},{"location":"#CodecLZO","page":"Home","title":"CodecLZO","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for CodecLZO.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [CodecLZO]","category":"page"},{"location":"#CodecLZO.compress_block-Union{Tuple{F}, Tuple{AbstractVector{UInt8}, IO, LibLZO.AbstractLZOAlgorithm}} where F<:Function","page":"Home","title":"CodecLZO.compress_block","text":"compress_block(input, output, algo; [kwargs...])::Tuple{Int,Int}\n\nCompress a block of data from `input` to `output` using LZO algorithm `algo`, returning the number of bytes read from `input` and written to `output`.\n\nArguments\n\ninput: An AbstractVector{UInt8} or IO object containing the block of data to compress.\noutput::IO: Output IO object to write the compressed block.\n\nKeyword arguments\n\nblock_size::Integer = LZOP_DEFAULT_BLOCK_SIZE: Number of bytes to read from input. Will cap at LZOP_MAX_BLOCK_SIZE.\ncrc32::Bool = false: If true, write a CRC-32 checksum for both uncompressed and compressed data. If false, write Adler32 checksums instead.\nfilter_function::Function = identity: Transform the input data using the specified filter functions. The filter function must accept a single AbstractVector{UInt8} argument and must modify that vector in-place.\noptimize::Bool = false: If true, process the data twice to optimize how it is stored for faster decompression. Setting this to true doubles compression time with little to no improvement in decompression time, so its use is not recommended.\n\n\n\n\n\n","category":"method"},{"location":"#CodecLZO.decompress_block-Union{Tuple{F}, Tuple{IO, IO, LibLZO.AbstractLZOAlgorithm}} where F<:Function","page":"Home","title":"CodecLZO.decompress_block","text":"decompress_block(input, output, algo; [kwargs...])::Tuple{Int,Int}\n\nDecompress a block of data from `input` to `output` using LZO algorithm `algo`, returning the number of bytes read from `input` and written to `output`.\n\nArguments\n\ninput: An AbstractVector{UInt8} or IO object containing the block of LZO-compressed data to decompress.\noutput::IO: Output IO object to write the decompressed block.\n\nKeyword arguments\n\n'crc32::Bool = false: Iftrue, assume the checksum written to the block for both uncompressed and compressed data is a CRC-32 checksum. Iffalse`, assume Adler32 checksums instead.\nfilter_function::Function = identity: Untransform the output data using the specified filter function. The filter function must take a single AbstractVector{UInt8} argument and modify it in place.\non_checksum_fail::Symbol = :throw: Choose how the function responds to invalud checksums. If :throw, an ErrorException will be thrown. If :warn, a warning will be printed. If :ignore, the checksum values will be completely ignored.\n\n\n\n\n\n","category":"method"}]
}