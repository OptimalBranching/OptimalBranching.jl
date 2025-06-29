module OptimalBranchingMIS

using OptimalBranchingCore
using OptimalBranchingCore: AbstractProblem, intersect_clauses, candidate_clauses
using OptimalBranchingCore.BitBasis
using OptimalBranchingCore.JuMP, OptimalBranchingCore.HiGHS
using Combinatorics
using EliminateGraphs, EliminateGraphs.Graphs
using GenericTensorNetworks
using SparseArrays
using ProblemReductions: IndependentSet

export MISProblem
export MISReducer, BasicReducer, XiaoReducer, TensorNetworkReducer, SubsolverReducer
export MinBoundarySelector, MinBoundaryHighDegreeSelector, KaHyParSelector

export TensorNetworkSolver
export NumOfVertices, D3Measure

export mis_size, mis_branch_count
export ip_mis
export counting_mis1, counting_mis2, counting_xiao2013, counting_xiao2021

include("types.jl")
include("graphs.jl")
include("algorithms/algorithms.jl")

include("reducer.jl")
include("selector.jl")
include("tablesolver.jl")
include("branch.jl")

include("interfaces.jl")

end
