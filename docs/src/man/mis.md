```@meta
CurrentModule = OptimalBranchingMIS
```

# OptimalBranchingMIS

## The maximum independent set problem

The maximum independent set problem is a classical combinatorial optimization problem, which is to find the largest subset of vertices in a graph such that no two vertices in the subset are adjacent.

## Designing a branch-and-reduce algorithm using the optimal branching algorithm

To solve the MIS problem, we use the framework provided by the `OptimalBranchingCore` package to design a branch-and-reduce algorithm.

## API

```@autodocs
Modules = [OptimalBranchingMIS]
Order = [:macro, :function, :type, :module]
```