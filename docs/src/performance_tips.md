# Performance Tips

## Using a better integer programming solver

Solving the optimal branching rule involves solving a weighted minimum set cover problem, which is converted to an integer programming problem and solved by [`IPSolver`](@ref).
For branching regions with a large number of variables, the performance of the solver may be the bottleneck of the whole algorithm.
We set the default integer programming solver to `HiGHS`, which can be ~10x slower comparing with the state-of-the-art commercial solvers such as Gurobi and CPLEX.

To get a better understanding of the performance of different integer programming solvers, we recommend reading [this issue](https://github.com/OptimalBranching/OptimalBranching.jl/issues/36).

In the following example, we switch the integer programming solver to `SCIP` (at version 0.11) to solve the problem.

```@repl performance_tips
using OptimalBranching, Graphs
using OptimalBranching.OptimalBranchingCore
using SCIP
g = smallgraph(:tutte)
branching_strategy = BranchingStrategy(
    table_solver = TensorNetworkSolver(),
    selector = MinBoundarySelector(2),
    measure = D3Measure(),
    set_cover_solver = IPSolver(optimizer = SCIP.Optimizer)
)
mis_size(g; branching_strategy, reducer = MISReducer())
```

If approximately optimal branching rules are acceptable, one can also use the linear relaxation of the set cover problem to solve the problem.
```@repl performance_tips
branching_strategy_lp = BranchingStrategy(
    table_solver = TensorNetworkSolver(),
    selector = MinBoundarySelector(2),
    measure = D3Measure(),
    set_cover_solver = LPSolver()
)
mis_size(g; branching_strategy = branching_strategy_lp, reducer = MISReducer())
```
The default backend is also `HiGHS`. While the result is consistent, the rule searching is usually faster.
