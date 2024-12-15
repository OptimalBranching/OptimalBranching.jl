```@meta
CurrentModule = OptimalBranchingCore
DocTestSetup = quote
    using OptimalBranching
    using OptimalBranchingCore
    using BitBasis
end
```

# [OptimalBranchingCore](@id core)

## Literal, Clause and DNF

Literals, clauses and disjunctive normal form (DNF) are basic concepts in boolean logic, where literals are boolean variables, clauses are boolean expressions, and DNF is a disjunction of one or more conjunctions of literals.

Here is an example, given a truth table as follows:

| a | b | c | value |
|:---:|:---:|:---:|:---:|
| 0 | 0 | 0 |   1   |
| 0 | 0 | 1 |   1   |
| 0 | 1 | 0 |   0   |
| 0 | 1 | 1 |   0   |
| 1 | 0 | 0 |   0   |
| 1 | 0 | 1 |   1   |
| 1 | 1 | 0 |   0   |
| 1 | 1 | 1 |   0   |

where $a, b, c$ are boolean variables called literals.
The true statements can be represented as a conjunction of literals, for example, 

$$\neg a \land \neg b \land \neg c, \neg a \land \neg b \land c, a \land \neg b \land c$$

and these clauses can be combined into a DNF:

$$(\neg a \land \neg b) \lor (a \land \neg b \land c).$$

In `OptimalBranchingCore`, a clause is represented by the [`Clause`](@ref) type, and a DNF is represented by the [`DNF`](@ref) type, based on the `BitBasis.jl` package.
```@repl core
using OptimalBranchingCore, BitBasis
c1 = Clause(bit"011", bit"000")
c2 = Clause(bit"111", bit"101")
dnf = DNF(c1, c2)
```

## The branch and bound algorithm

The branch and bound algorithm is a method to exactly solve the combinatorial optimization problems.



## API

```@autodocs
Modules = [OptimalBranchingCore]
Order = [:macro, :function, :type, :module]
```