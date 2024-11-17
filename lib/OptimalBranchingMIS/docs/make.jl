using OptimalBranchingMIS
using Documenter

DocMeta.setdocmeta!(OptimalBranchingMIS, :DocTestSetup, :(using OptimalBranchingMIS); recursive=true)

makedocs(;
    modules=[OptimalBranchingMIS],
    authors="Xuanzhao Gao <gaoxuanzhao@gmail.com> and contributors",
    sitename="OptimalBranchingMIS.jl",
    format=Documenter.HTML(;
        canonical="https://ArrogantGao.github.io/OptimalBranchingMIS.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranchingMIS.jl",
    devbranch="main",
)
