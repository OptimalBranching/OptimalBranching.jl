using OptimalBranchingAPI
using Documenter

DocMeta.setdocmeta!(OptimalBranchingAPI, :DocTestSetup, :(using OptimalBranchingAPI); recursive=true)

makedocs(;
    modules=[OptimalBranchingAPI],
    authors="Xuanzhao Gao <gaoxuanzhao@gmail.com> and contributors",
    sitename="OptimalBranchingAPI.jl",
    format=Documenter.HTML(;
        canonical="https://ArrogantGao.github.io/OptimalBranchingAPI.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranchingAPI.jl",
    devbranch="main",
)
