module OptimalBranchingMIS

using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using Combinatorics
using EliminateGraphs, EliminateGraphs.Graphs
using GenericTensorNetworks

export MISProblem
export MISCount
export MISReducer, XiaoReducer
export MinBoundarySelector
export TensorNetworkSolver
export NumOfVertices, D3Measure

export counting_mis1, counting_mis2, counting_xiao2013

include("types.jl")
include("graphs.jl")
include("algorithms/mis1.jl")
include("algorithms/mis2.jl")
include("algorithms/xiao2013.jl")
include("algorithms/xiao2013_utils.jl")

include("reducer.jl")
include("selector.jl")
include("tablesolver.jl")
include("branch.jl")

end
