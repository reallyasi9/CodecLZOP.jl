using CodecLZOP
using Documenter

DocMeta.setdocmeta!(CodecLZOP, :DocTestSetup, :(using CodecLZOP); recursive=true)

makedocs(;
    modules=[CodecLZOP],
    authors="Phil Killewald <reallyasi9@users.noreply.github.com> and contributors",
    sitename="CodecLZOP.jl",
    format=Documenter.HTML(;
        canonical="https://reallyasi9.github.io/CodecLZOP.jl",
        edit_link="development",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/reallyasi9/CodecLZOP.jl",
    devbranch="development",
)
