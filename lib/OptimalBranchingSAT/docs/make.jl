using OptimalBranchingSAT
using Documenter

DocMeta.setdocmeta!(OptimalBranchingSAT, :DocTestSetup, :(using OptimalBranchingSAT); recursive=true)

makedocs(;
    modules=[OptimalBranchingSAT],
    authors="Xuanzhao Gao <gaoxuanzhao@gmail.com> and contributors",
    sitename="OptimalBranchingSAT.jl",
    format=Documenter.HTML(;
        canonical="https://ArrogantGao.github.io/OptimalBranchingSAT.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranchingSAT.jl",
    devbranch="main",
)
