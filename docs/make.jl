using OptimalBranching
using Documenter

DocMeta.setdocmeta!(OptimalBranching, :DocTestSetup, :(using OptimalBranching); recursive=true)

makedocs(;
    modules=[OptimalBranching, OptimalBranchingCore, OptimalBranchingMIS],
    authors="Xuanzhao Gao <gaoxuanzhao@gmail.com> and contributors",
    sitename="OptimalBranching.jl",
    format=Documenter.HTML(;
        canonical="https://ArrogantGao.github.io/OptimalBranching.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranching.jl",
    devbranch="main",
)
