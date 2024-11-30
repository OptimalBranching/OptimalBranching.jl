module OptimalBranchingCore

using JuMP, HiGHS, SCIP
using AbstractTrees
using BitBasis

export complexity_bv
export Clause, BranchingTable, CandidateClause, DNF, Branch
export BranchingStrategy
export AbstractProblem, AbstractMeasure, AbstractReducer, AbstractSelector, AbstractTableSolver, AbstractSetCoverSolver
export LPSolver, IPSolver

export MaxSize, MaxSizeBranchCount

export apply_branch, measure, reduce_problem, select, branching_table, weighted_minimum_set_cover
export reduce_and_branch, optimal_branching_rule

include("algebra.jl")
include("bitbasis.jl")
include("interfaces.jl")
include("setcovering.jl")
include("branching_table.jl")
include("branch.jl")

end
