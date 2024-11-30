module OptimalBranchingMIS

using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using Combinatorics
using EliminateGraphs, EliminateGraphs.Graphs
using GenericTensorNetworks

export MISProblem
export MISReducer, XiaoReducer
export MinBoundarySelector
export TensorNetworkSolver
export NumOfVertices, D3Measure

export counting_mis1, counting_mis2, counting_xiao2013

include("types.jl")
include("graphs.jl")
include("algorithms/algorithms.jl")

include("reducer.jl")
include("selector.jl")
include("tablesolver.jl")
include("branch.jl")

end
