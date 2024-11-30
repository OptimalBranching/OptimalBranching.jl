module OptimalBranchingCore

using JuMP, HiGHS, SCIP
using BitBasis

# highest level API
export BranchingStrategy, reduce_and_branch, optimal_branching_rule

# problem and complexity measure
export AbstractProblem
export measure, AbstractMeasure

# reduce problem
export AbstractReducer, reduce_problem

# select variables
export AbstractSelector, select_variables

# solve the relevant configurations
export AbstractTableSolver, branching_table

# logic expression and set covering solver
export booleans, Clause, BranchingTable, DNF, ¬, ∨, ∧
export AbstractSetCoverSolver, LPSolver, IPSolver, weighted_minimum_set_cover

include("bitbasis.jl")
include("interfaces.jl")
include("setcovering.jl")
include("branching_table.jl")
include("branch.jl")

end
