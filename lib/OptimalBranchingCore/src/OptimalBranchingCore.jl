module OptimalBranchingCore

using NLsolve, JuMP, HiGHS, SCIP
using AbstractTrees
using BitBasis

export Clause, BranchingTable, SubCover, DNF, Branch
export SolverConfig
export AbstractBranchingStrategy, OptBranchingStrategy
export AbstractProblem, AbstractResult, AbstractMeasure, AbstractReducer, AbstractSelector, AbstractPruner, AbstractTableSolver, AbstractSetCoverSolver
export NoResult, NoPruner, LPSolver, IPSolver

export apply_branch, measure, reduce_problem, select, branching_table, prune, weighted_minimum_set_cover
# TODO: complexity should be implemented on BranchingRule
export complexity, reduce_and_branch, optimal_branching_rule

include("bitbasis.jl")
include("types.jl")
include("setcovering.jl")
include("branch.jl")

end
