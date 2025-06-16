<img src="logo-wide.svg" width=500>

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://optimalbranching.github.io/OptimalBranching.jl/dev/)
[![Build Status](https://github.com/OptimalBranching/OptimalBranching.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/OptimalBranching/OptimalBranching.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/OptimalBranching/OptimalBranching.jl/graph/badge.svg?token=GF1R6ZEVVL)](https://codecov.io/gh/OptimalBranching/OptimalBranching.jl)

`OptimalBranching.jl` is a collection of tools for solving combinatorial optimization problems with branch-and-reduce method.
It is written in Julia and features automatically generated branching rules with provable optimality ([arXiv: 2412.07685](https://arxiv.org/abs/2412.07685)).
The rule generation is problem agnostic, and it can be easily extended to other problems.
It contains two submodules:
* `OptimalBranchingCore.jl`: the core algorithms, which convert the problem of searching the optimal branching rule into the problem of searching the optimal set cover.
* `OptimalBranchingMIS.jl`: the maximum independent set (MIS) problem solver based on the optimal branching algorithms.


## Installation

<p>
OptimalBranching is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install OptimalBranching,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command
</p>

```julia
pkg> add OptimalBranchingCore  # for the core algorithms

pkg> add OptimalBranching      # for utilities based on the core algorithms
```

If you have problem to install the package, please [file us an issue](https://github.com/OptimalBranching/OptimalBranching.jl/issues/new).

## Get started

```julia
julia> using OptimalBranching, OptimalBranching.OptimalBranchingMIS.Graphs

julia> graph = smallgraph(:tutte)
{46, 69} undirected simple Int64 graph

julia> mis_branch_count(graph)
(19, 2)
```
In this example, the maximum independent set size of the Tutte graph is 19, and the optimal branching strategy only generates 2 branches in the branching tree.

For advanced usage, please refer to the [documentation](https://OptimalBranching.github.io/OptimalBranching.jl/dev/).

## How to Contribute

If you find any bug or have any suggestion, please open an [issue](https://github.com/OptimalBranching/OptimalBranching.jl/issues).

## Citation

If you find this package useful in your research, please cite the relevant paper in the [CITATION.bib](CITATION.bib) file.
