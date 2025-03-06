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
mis_size(g) # the size of the maximum independent set (MIS)
mis_branch_count(g) # MIS size and the number of branches used in calculation
```

One can also select different strategies to solve the problem, which inclues 
* [`AbstractTableSolver`](@ref) to solve the [`BranchingTable`](@ref), 
* [`AbstractSelector`](@ref) to select the branching variable, 
* [`AbstractMeasure`](@ref) to measure the size of the problem, 
* [`AbstractSetCoverSolver`](@ref) to solve the set cover problem, and 
* [`AbstractReducer`](@ref) to reduce the problem.
Here is an example:

```@repl quick-start
branching_strategy = BranchingStrategy(
    table_solver = TensorNetworkSolver(), 
    selector = MinBoundarySelector(2), 
    measure = D3Measure(), 
    set_cover_solver = IPSolver()
)
mis_size(g; branching_strategy, reducer = MISReducer())
```

One can also use the [`branch_and_reduce`](@ref) function to solve the problem, which is more flexible.
```@repl quick-start
branch_and_reduce(MISProblem(g), branching_strategy, MISReducer(), MaxSizeBranchCount)
```

## The optimal branching rule

We first specify a branching table, which is a table of bitstrings that the rule needs to cover.
At least one bitstring in each row of the table is needed to be covered.

```@repl quick-start
using OptimalBranchingCore
tbl = BranchingTable(5, [
        [[0, 0, 0, 0, 1], [0, 0, 0, 1, 0]],
        [[0, 0, 1, 0, 1]],
        [[0, 1, 0, 1, 0]],
        [[1, 1, 1, 0, 0]]])
```

Then, we generate the candidate clauses, which are the clauses forming the branching rule (a DNF formula).
```@repl quick-start
candidates = OptimalBranchingCore.candidate_clauses(tbl)
```

For each candidate clause, we calculate the size reduction of the problem after applying the clause. Here, we use a simple measure: counting the number of variables eliminated by the clause.
```@repl quick-start
Δρ = [length(literals(sc)) for sc in candidates]; println(Δρ)
```

Finally, we solve the set cover problem to find the optimal branching rule. The solver is set to be the [`IPSolver`](@ref). For more options, please refer to the [Performance Tips](@ref) section.
```@repl quick-start
res_ip = OptimalBranchingCore.minimize_γ(tbl, candidates, Δρ, IPSolver())
```

The result is an instance of [`OptimalBranchingResult`](@ref), which contains the selected clauses, the optimal branching rule, and the branching vector.
