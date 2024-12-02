using OptimalBranching, OptimalBranchingCore, OptimalBranchingMIS
using Documenter
using Literate

# Literate
for each in readdir(pkgdir(OptimalBranching, "examples"))
    input_file = pkgdir(OptimalBranching, "examples", each)
    endswith(input_file, ".jl") || continue
    @info "building" input_file
    output_dir = pkgdir(OptimalBranching, "docs", "src", "generated")
    Literate.markdown(input_file, output_dir; name=each[1:end-3], execute=false)
end

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
        "Examples" => [
            "generated/rule_discovery.md",
        ],
        "Manual" => Any[
            "man/core.md",
            "man/mis.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/ArrogantGao/OptimalBranching.jl",
    devbranch="main",
)
