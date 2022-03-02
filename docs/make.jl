using LinearMixingModels
using Documenter

DocMeta.setdocmeta!(
    LinearMixingModels,
    :DocTestSetup,
    :(using LinearMixingModels, KernelFunctions, FillArrays, LinearAlgebra, AbstractGPs);
    recursive=true,
)

makedocs(;
    modules=[LinearMixingModels],
    authors="Invenia Technical Computing Corporation",
    repo="https://github.com/invenia/LinearMixingModels.jl/blob/{commit}{path}#{line}",
    sitename="LinearMixingModels.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://invenia.github.io/LinearMixingModels.jl",
        assets=["assets/invenia.css"],
    ),
    pages=["Home" => "index.md", "API" => "api.md"],
    checkdocs=:exports,
    strict=true,
)

deploydocs(;
    repo="github.com/invenia/LinearMixingModels.jl",
)
