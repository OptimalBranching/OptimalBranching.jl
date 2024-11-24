# OptimalBranchingMIS

`OptimalBranchingMIS` is a developed based on `OptimalBranchingCore` for the optimal branching method on the maximum independent set (MIS) problem.

## Usage 

In this pacakge a set of tools for MIS problem has been provided, including:
* `MISProblem`: the problem type for MIS
* `MISReducer`: the reducer for MIS
* `MISSize` & `MISCount`: different types for the results, returning the size of the maximum independent set or together with the count of branches
* `MinBoundarySelector`: the selectors for the minimum boundary size
* `NumofVertex` & `D3Measure`: different measures for the MIS problem

Additionally, we provide `counting_mis1` and `counting_mis2` functions for counting the maximum independent sets, which are based on the `EliminateGraphs` package.

For more details, please refer to the [docs]().