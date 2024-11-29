module OptimalBranchingCore

using NLsolve, JuMP, HiGHS, SCIP
using AbstractTrees
using BitBasis

export Clause, BranchingTable, CandidateClause, DNF, Branch
export SolverConfig
export AbstractBranchingStrategy, OptBranchingStrategy
export AbstractProblem, AbstractResult, AbstractMeasure, AbstractReducer, AbstractSelector, AbstractPruner, AbstractTableSolver, AbstractSetCoverSolver
export NoResult, NoPruner, LPSolver, IPSolver

export apply_branch, measure, reduce_problem, select, branching_table, weighted_minimum_set_cover
# TODO: complexity should be implemented on BranchingRule
export reduce_and_branch, optimal_branching_rule

include("bitbasis.jl")
include("interfaces.jl")
include("setcovering.jl")
include("branch.jl")

end
