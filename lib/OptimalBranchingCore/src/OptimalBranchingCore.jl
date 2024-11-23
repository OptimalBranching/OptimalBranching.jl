module OptimalBranchingCore

using NLsolve, JuMP, HiGHS, SCIP
using GenericTensorNetworks
using AbstractTrees

using Reexport
@reexport using BitBasis

export Clause, BranchingTable, SubCover, DNF, Branch
export SolverConfig
export AbstractBranchingStrategy, NoBranchingStrategy, OptBranchingStrategy
export AbstractProblem, AbstractResult, AbstractMeasure, AbstractReducer, AbstractSelector, AbstractPruner, AbstractTableSolver, AbstractSetCoverSolver
export NoProblem, NoResult, NoMeasure, NoReducer, NoSelector, NoPruner, NoTableSolver, LPSolver, IPSolver

export apply, measure, problem_reduce, select, solve_table, prune
export complexity, cover, branch

include("bitbasis.jl")
include("subcover.jl")
include("types.jl")
include("setcovering.jl")
include("branch.jl")
# include("branchingtree.jl")

end
