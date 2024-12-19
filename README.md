# OptimalBranching.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/dev/)
[![Build Status](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl)


`OptimalBranching.jl` is a Julia package that implements the optimal branching algorithm (paper coming soon). It is a meta package that contains the following submodules in the `lib` directory:
- `OptimalBranchingCore.jl`: the core algorithms for automatically generating optimal branching rules.
- `OptimalBranchingMIS.jl`: the maximum independent set solver based on the optimal branching algorithm.

## Installation

This package has already been registered, one can press `]` to enter the package manager and then enter
```julia
pkg> add OptimalBranching
```
to install the package.

To use the latest version, one can install this repository manually by

```bash
$ git clone https://github.com/ArrogantGao/OptimalBranching.jl
$ cd OptimalBranching.jl
$ make
```

This will add the submodules and install the dependencies, the tests will be run automatically to ensure everything is fine.

## Get started

Please stay in the project directory and type
```bash
$ julia --project
```
to start a Julia session in the project environment. Then you can test the functions by typing
```julia
julia> using OptimalBranching, OptimalBranchingMIS.Graphs

julia> graph = smallgraph(:tutte)
{46, 69} undirected simple Int64 graph

julia> mis_branch_count(graph)
(19, 2)
```
In this example, the maximum independent set size of the Tutte graph is 19, and the optimal branching strategy only generates 2 branches in the branching tree.

For advanced usage, please refer to the [documentation](https://ArrogantGao.github.io/OptimalBranching.jl/dev/).

## How to Contribute

If you find any bug or have any suggestion, please open an [issue](https://github.com/ArrogantGao/OptimalBranching.jl/issues).
