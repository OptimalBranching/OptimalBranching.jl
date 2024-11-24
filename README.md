# OptimalBranching.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ArrogantGao.github.io/OptimalBranching.jl/dev/)
[![Build Status](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ArrogantGao/OptimalBranching.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ArrogantGao/OptimalBranching.jl)


`OptimalBranching.jl` is a Julia package for automatic generation of optimal branching rule for the branch-and-bound algorithm.
This package only supply an interface for the core algorithm, and the actual implementation of the core algorithm is in `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl`, which can be found in the `lib` directory of this repository.

## Installation

This package has not been registered yet, so you need to add this repository manually.

```bash
$ git clone https://github.com/ArrogantGao/OptimalBranching.jl
$ cd OptimalBranching.jl
$ make
```

This will add the submodules `OptimalBranchingCore.jl` and `OptimalBranchingMIS.jl` and install the dependencies, the tests will be run automatically to ensure everything is fine.

## Dependencies

The relation between the submodules and the package is shown in the following diagram:
```
                           |-- OptimalBranchingSAT.jl --|
OptimalBranchingCore.jl -->|                            |--> OptimalBranching.jl
                           |-- OptimalBranchingMIS.jl --|
```
where `OptimalBranching.jl` is only a package interface.

For more details, please refer to the [documentation](https://ArrogantGao.github.io/OptimalBranching.jl/dev/).

## How to Contribute

If you find any bug or have any suggestion, please open an [issue](https://github.com/ArrogantGao/OptimalBranching.jl/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
