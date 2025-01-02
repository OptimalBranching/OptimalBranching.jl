module OptimalBranchingCore

using JuMP, HiGHS
using BitBasis

# logic expressions
export Clause, BranchingTable, DNF, booleans, ∨, ∧, ¬, covered_by, literals, is_true_literal, is_false_literal
# weighted minimum set cover solvers and optimal branching rule
export weighted_minimum_set_cover, AbstractSetCoverSolver, LPSolver, IPSolver
export minimize_γ, optimal_branching_rule, OptimalBranchingResult

##### interfaces #####
# high-level interface
export AbstractProblem, branch_and_reduce, BranchingStrategy

# variable selector interface
export select_variable, AbstractSelector
# branching table solver interface
export branching_table, AbstractTableSolver
# measure interface
export measure, AbstractMeasure
# reducer interface
export reduce_problem, AbstractReducer, NoReducer
# return type
export MaxSize, MaxSizeBranchCount

include("algebra.jl")
include("bitbasis.jl")
include("interfaces.jl")
include("branching_table.jl")
include("setcovering.jl")
include("branch.jl")
include("greedymerge.jl")
end
