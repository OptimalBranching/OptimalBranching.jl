struct MockProblem <: AbstractProblem
    optimal::BitVector
end

"""
    NumOfVariables

A struct representing a measure that counts the number of variables in a problem. 
Each variable is counted as 1.
"""
struct NumOfVariables <: AbstractMeasure end
measure(p::MockProblem, ::NumOfVariables) = length(p.optimal)


"""
    struct RandomSelector <: AbstractSelector

The `RandomSelector` struct represents a strategy for selecting a subset of variables randomly.

# Fields
- `n::Int`: The number of variables to select.
"""
struct RandomSelector <: AbstractSelector
    n::Int
end
function select_variables(p::MockProblem, ::NumOfVariables, selector::RandomSelector)
    nv = min(length(p.optimal), selector.n)
    return sortperm(rand(length(p.optimal)))[1:nv]
end

"""
    struct MockTableSolver <: AbstractTableSolver

The `MockTableSolver` randomly generates a branching table with a given number of rows.
Each row must have at least one variable to be covered by the branching rule.

### Fields
- `n::Int`: The number of rows in the branching table.
- `p::Float64 = 0.0`: The probability of generating more than one variables in a row, following the Poisson distribution.
"""
struct MockTableSolver <: AbstractTableSolver
    n::Int
    p::Float64
end
MockTableSolver(n::Int) = MockTableSolver(n, 0.0)
function branching_table(p::MockProblem, table_solver::MockTableSolver, variables)
    function rand_fib()  # random independent set on 1D chain
        bs = falses(length(variables))
        for i=1:length(variables)
            if rand() < min(0.5, i == 1 ? 1.0 : 1 - bs[i-1])
                bs[i] = true
            end
        end
        return bs
    end
    rows = unique!([[rand_fib()] for _ in 1:table_solver.n] ∪ [[p.optimal[variables]]])
    for i in 1:length(rows)
        for _ = 1:100
            if rand() < table_solver.p
                push!(rows[i], rand_fib())
            else
                break
            end
        end
    end
    return BranchingTable(length(variables), unique!.(rows))
end

function OptimalBranchingCore.apply_branch(p::MockProblem, clause::Clause{INT}, variables::Vector{T}) where {INT<:Integer, T<:Integer}
    @show clause
    return MockProblem([p.optimal[i] for i in 1:length(p.optimal) if (i ∉ variables || iszero(readbit(clause.mask, findfirst(==(i), variables))))]), count(i -> isone(readbit(clause.mask, i)) && (readbit(clause.val, i) == p.optimal[variables[i]]), 1:length(variables))
end
is_solved(p::MockProblem) = measure(p, NumOfVariables()) == 0
