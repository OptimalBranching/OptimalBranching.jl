# OptimalBranchingCore

Core functions and types for the optimal branching method. One can use it separately or as part of the `OptimalBranching` package.

## Usage

`OptimalBranchingCore` provides the basis tools for developing a branching algorithm, by dividing the branching process into the following steps:
* Reduction of the problem
* Generation of the branches
* Applying the branching rules on the problem

For the optimal branching method, the generation of the branches is further divided into the following sub-steps:
* Solving the branching table
* Pruning the branches
* Selecting the optimal branching rule via the set covering solver

For more details, please refer to the [docs]().