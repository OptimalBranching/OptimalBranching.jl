module OptimalBranchingCore

using NLsolve, JuMP, HiGHS, SCIP
using AbstractTrees
using BitBasis

export Clause, BranchingTable, SubCover, DNF, Branch
export SolverConfig
export AbstractBranchingStrategy, OptBranchingStrategy
export AbstractProblem, AbstractResult, AbstractMeasure, AbstractReducer, AbstractSelector, AbstractPruner, AbstractTableSolver, AbstractSetCoverSolver
export NoProblem, NoResult, NoPruner, LPSolver, IPSolver

export apply, measure, problem_reduce, select, solve_table, prune, weighted_minimum_set_cover
export complexity, minimum_γ, branch, solve_branches, optimal_branching, viz_optimal_branching

include("bitbasis.jl")
include("subcover.jl")
include("types.jl")
include("setcovering.jl")
include("branch.jl")
# include("branchingtree.jl")

end
