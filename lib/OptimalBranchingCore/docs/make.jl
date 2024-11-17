using OptimalBranchingCore
using Documenter

DocMeta.setdocmeta!(OptimalBranchingCore, :DocTestSetup, :(using OptimalBranchingCore); recursive=true)

makedocs(;
    modules=[OptimalBranchingCore],
    authors="Xuanzhao Gao <gaoxuanzhao@gmail.com> and contributors",
    sitename="OptimalBranchingCore.jl",
    format=Documenter.HTML(;
        canonical="https://ArrogantGao.github.io/OptimalBranchingCore.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranchingCore.jl",
    devbranch="main",
)
