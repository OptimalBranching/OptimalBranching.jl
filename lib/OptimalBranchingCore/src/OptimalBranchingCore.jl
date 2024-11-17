module OptimalBranchingCore

using NLsolve, JuMP, HiGHS, SCIP
using BitBasis, GenericTensorNetworks
using AbstractTrees

export Clause, BranchingTable, SubCover, DNF
export subcovers

include("bitbasis.jl")
include("subcover.jl")
include("strategy.jl")
include("setcover.jl")

end
