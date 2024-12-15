```@meta
CurrentModule = OptimalBranching
DocTestSetup = quote
    using OptimalBranching
    using OptimalBranchingCore
    using Graphs
end
```

# Quick Start

This section will provide a brief introduction about how to use the `OptimalBranching.jl` package.

## The maximum independent set problem

We provided two simple interfaces to solve the maximum independent set problem and count the branches used in calculation.

```@repl quick-start
using OptimalBranching, Graphs
g = smallgraph(:tutte)
mis_size(g) # this gives the size of the maximum independent set
mis_branch_count(g) # this gives the size of the maximum independent set and the number of branches used in calculation
```

One can also select different strategies to solve the problem, which inclues 
* [`AbstractTableSolver`](@ref) to solve the [`BranchingTable`](@ref), 
* [`AbstractSelector`](@ref) to select the branching variable, 
* [`AbstractMeasure`](@ref) to measure the size of the problem, 
* [`AbstractSetCoverSolver`](@ref) to solve the set cover problem, and 
* [`AbstractReducer`](@ref) to reduce the problem.
Here is an example:

```@repl quick-start
using OptimalBranchingCore, OptimalBranching, Graphs
branching_strategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure(), set_cover_solver = IPSolver())
mis_size(g, bs = branching_strategy, reducer = MISReducer())
```

One can also use the [`branch_and_reduce`](@ref) function to solve the problem, which is more flexible.
```@repl quick-start
using OptimalBranchingCore, OptimalBranching, Graphs
branching_strategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure(), set_cover_solver = IPSolver())
branch_and_reduce(MISProblem(g), branching_strategy, MISReducer(), MaxSizeBranchCount)
```
