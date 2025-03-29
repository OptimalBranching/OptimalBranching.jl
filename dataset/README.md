# Data description

The dataset contains JSON files with optimal branching rules generated for mock problems. Each file is named according to the parameters used: `optimal_branching_result-n=X-nstrings=Y.json`, where:
- `X` is the number of variables (bit length)
- `Y` is the number of strings (samples) used in the branching table

Each JSON file contains an array of samples, where each sample has:

1. `input_table`: A dictionary representing the branching table with:
   - `bit_length`: Number of variables
   - `rows`: A nested array where each row contains bit strings (represented as arrays of 0s and 1s)

2. `optimal_rule`: A dictionary containing:
   - `rule`: An array of clauses, where each clause is represented as an array of integers. 
     - Each position corresponds to a variable
     - `-1` means the variable is not used in the clause
     - `0` or `1` indicates the required value for that variable
   - `gamma`: The γ value determined by the equation 1 = sum_c γ^(num_literals(c)), where c is a clause in the optimal rule

The files are generated using the `gen_ob.jl` script, which creates mock problems and computes optimal branching rules using the `OptimalBranchingCore` package.

## Objective

The goal is to learn the optimal branching rule from the input branching table. The branching rule is a DNF formula:

```math
c_1 \lor c_2 \lor ... \lor c_k
```
where each clause $c_i$ is a disjunction of variables:
```math
x_{i_1} \lor x_{i_2} \lor ... \lor x_{i_{l_i}}
```
where $x_{i_j}$ is a variable and $l_i$ is the number of variables in the $i$-th clause.

The rule must satisfy the following constraint:
- Must be satisfied by at least one bitstring in each row of the branching table.

The quality of the rule is measured by $\gamma \in [1, 2]$. The lower the better.