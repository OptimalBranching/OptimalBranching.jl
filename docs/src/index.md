```@meta
CurrentModule = OptimalBranching
```

# OptimalBranching.jl

Welcome to [OptimalBranching](https://github.com/ArrogantGao/OptimalBranching.jl).
`OptimalBranching.jl` is a Julia package for automatic generation of optimal branching rule for the branch-and-bound algorithm.

## Installation

To install the package, one can press `]` to enter the `package` mode and enter
```julia
pkg> add https://github.com/ArrogantGao/OptimalBranching.jl
```

To use the latest version of the package, you can compile the source code locally by

```bash
$ git clone https://github.com/ArrogantGao/OptimalBranching.jl
$ cd OptimalBranching.jl
$ make
```

This will add the submodules `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl` and install the dependencies, the tests will be run automatically to ensure everything is fine.

## Dependencies

The relation between the submodules and the package is shown in the following diagram:
```
OptimalBranchingCore.jl --> OptimalBranchingMIS.jl --> OptimalBranching.jl
```
where `OptimalBranchingCore.jl` contains the core algorithms, which convert the problem of searching the optimal branching rule into the problem of searching the optimal set cover, and `OptimalBranchingMIS.jl` is developed base on the optimal branching algorithms to solve the maximum independent set (MIS) problem, and `OptimalBranching.jl` is a package interface.

## Quick Starts

You can learn how to use `OptimalBranching.jl` with some quick examples in this section.
The examples are about how to use the current implemented optimal branching algorithms to solve the maximum independent set (MIS) problem, and a brief introduction about extending the package to other method and problem will be provided.

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

If you find any bug or have any suggestion, please open an [issue](https://github.com/ArrogantGao/OptimalBranching.jl/issues).

## License

This project is licensed under the MIT License.

## Citation

If you find this package useful in your research, please cite the following paper:

```
@misc{gao2024automateddiscoverybranchingrules,
      title={Automated Discovery of Branching Rules with Optimal Complexity for the Maximum Independent Set Problem}, 
      author={Xuan-Zhao Gao and Yi-Jia Wang and Pan Zhang and Jin-Guo Liu},
      year={2024},
      eprint={2412.07685},
      archivePrefix={arXiv},
      primaryClass={math.OC},
      url={https://arxiv.org/abs/2412.07685}, 
}
```
