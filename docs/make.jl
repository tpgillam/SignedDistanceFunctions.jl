using SignedDistanceFunctions
using Documenter

DocMeta.setdocmeta!(SignedDistanceFunctions, :DocTestSetup, :(using SignedDistanceFunctions); recursive=true)

makedocs(;
    modules=[SignedDistanceFunctions],
    authors="Tom Gillam <tpgillam@googlemail.com>",
    repo="https://github.com/tpgillam/SignedDistanceFunctions.jl/blob/{commit}{path}#{line}",
    sitename="SignedDistanceFunctions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tpgillam.github.io/SignedDistanceFunctions.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/tpgillam/SignedDistanceFunctions.jl",
    devbranch="main",
)
