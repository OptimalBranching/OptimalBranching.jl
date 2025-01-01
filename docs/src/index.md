```@meta
CurrentModule = OptimalBranching
```

# OptimalBranching.jl

Welcome to [OptimalBranching](https://github.com/OptimalBranching/OptimalBranching.jl).
`OptimalBranching.jl` is a collection of tools for solving combinatorial optimization problems with branch-and-reduce method.
It is written in Julia and features automatically generated branching rules with provable optimality (arXiv: 2412.07685).
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

## Manual

*Note: This part is working in progress, for more details, please refer to the [paper](https://arxiv.org/abs/2412.07685).*

```@contents
Pages = [
    "man/core.md",
    "man/mis.md",
]
Depth = 1
```

## How to Contribute

If you find any bug or have any suggestion, please open an [issue](https://github.com/OptimalBranching/OptimalBranching.jl/issues).
To develop the package, just download the source code by

```bash
$ git clone https://github.com/OptimalBranching/OptimalBranching.jl
$ cd OptimalBranching.jl
$ make
```

This will add the submodules `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl` automatically, and the tests will be run automatically to ensure everything is fine.

## License

This project is licensed under the MIT License.

## Citation

If you find this package useful in your research, please cite the following paper:

```
@misc{Gao2024,
    title={Automated Discovery of Branching Rules with Optimal Complexity for the Maximum Independent Set Problem}, 
    author={Xuan-Zhao Gao and Yi-Jia Wang and Pan Zhang and Jin-Guo Liu},
    year={2024},
    eprint={2412.07685},
    archivePrefix={arXiv},
    primaryClass={math.OC},
    url={https://arxiv.org/abs/2412.07685}, 
}
```
