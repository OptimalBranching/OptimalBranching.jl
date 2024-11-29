"""
    BranchingTable{INT}

A table of branching configurations. The table is a vector of vectors of `INT`. Type parameters are:
- `INT`: The integer type for storing bit strings.

# Fields
- `bit_length::Int`: The length of the bit string.
- `table::Vector{Vector{INT}}`: The table of bitstrings used for branching.

To cover the branching table, at least one clause in each row must be satisfied.
"""
struct BranchingTable{INT <: Integer}
    bit_length::Int
    table::Vector{Vector{INT}}
end

function BranchingTable(n::Int, arr::AbstractVector{<:AbstractVector})
    @assert all(x->all(v->length(v) == n, x), arr)
    T = LongLongUInt{(n-1) ÷ 64 + 1}
    return BranchingTable(n, [_vec2int.(T, x) for x in arr])
end
# encode a bit vector to and integer
function _vec2int(::Type{T}, v::AbstractVector) where T <: Integer
    res = zero(T)
    for i in 1:length(v)
        res |= T(v[i]) << (i-1)
    end
    return res
end

nbits(t::BranchingTable) = t.bit_length
Base.:(==)(t1::BranchingTable, t2::BranchingTable) = all(x -> Set(x[1]) == Set(x[2]), zip(t1.table, t2.table))
function Base.show(io::IO, t::BranchingTable{INT}) where INT
    println(io, "BranchingTable{$INT}")
    for (i, row) in enumerate(t.table)
        print(io, join(["$(bitstring(r)[end-nbits(t)+1:end])" for r in row], ", "))
        i < length(t.table) && println(io)
    end
end
Base.show(io::IO, ::MIME"text/plain", t::BranchingTable) = show(io, t)
Base.copy(t::BranchingTable) = BranchingTable(t.bit_length, copy(t.table))

function covered_by(t::BranchingTable, dnf::DNF)
    all(x->any(y->covered_by(y, dnf), x), t.table)
end

struct BranchingRule{INT<:Integer}
    branches::Vector{Clause{INT}}
    γ::Float64
end

"""
    optimal_branching_rule(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R}

Generate optimal branches from a given branching table.

### Arguments
- `tbl::BranchingTable{INT}`: The branching table containing candidate clauses.
- `variables::Vector{T}`: A vector of variables to be used in the branching.
- `problem::P`: The problem instance being solved.
- `measure::M`: The measure used for evaluating the branches.
- `solver::S`: The solver used for the set cover problem.
- `::Type{R}`: The type of the result expected.
- `verbose::Bool`: Optional; if true, enables verbose output (default is false).

### Returns
A vector of `Branch` objects representing the optimal branches derived from the candidate clauses.
"""
function optimal_branching_rule(tbl::BranchingTable, variables::Vector, problem::AbstractProblem, measure::AbstractMeasure, solver::AbstractSetCoverSolver)
    candidates = candidate_clauses(tbl)
    Δρ = branching_vector(problem, variables, candidates, measure)
    selection, cx = minimize_γ(length(tbl.table), candidates, Δρ, solver)
    return BranchingRule(map(i->candidates[i].clause, selection), cx)
end

"""
    candidate_clauses(tbl::BranchingTable{INT}) where {INT}

Generates candidate_clauses from a branching table.

# Arguments
- `tbl::BranchingTable{INT}`: The branching table containing bit strings.

# Returns
- `Vector{CandidateClause{INT}}`: A vector of `CandidateClause` objects generated from the branching table.

# Description
This function calls the `candidate_clauses` function with the bit length and table from the provided branching table to generate the corresponding candidate_clauses.
"""
function candidate_clauses(tbl::BranchingTable{INT}) where {INT}
    n, bss = tbl.bit_length, tbl.table
    bs = vcat(bss...)
    all_clauses = Set{Clause{INT}}()
    temp_clauses = [Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)]
    while !isempty(temp_clauses)
        c = pop!(temp_clauses)
        if !(c in all_clauses)
            push!(all_clauses, c)
            idc = Set(covered_items(bss, c))
            for i in 1:length(bss)
                if i ∉ idc                
                    for b in bss[i]
                        c_new = gather2(n, c, Clause(bmask(INT, 1:n), b))
                        if (c_new != c) && c_new.mask != 0
                            push!(temp_clauses, c_new)
                        end
                    end
                end
            end
        end
    end

    allcovers = [CandidateClause(covered_items(bss, c), c) for c in all_clauses]
    return allcovers
end

function clause_string(clause::Clause{INT}, vs::Vector{T}) where {INT, T}
    cs_vec = String[]
    for i in 1:length(vs)
        if (clause.mask >> (i-1)) & 1 == 1
            t_flag = (clause.val >> (i-1)) & 1 == 1
            push!(cs_vec, t_flag ? "$(vs[i])" : "¬$(vs[i])")
        end
    end
    return join(cs_vec, " ∧ ")
end

"""
    AbstractPruner

An abstract type representing a pruner in the context of branching problems. 
This serves as a base type for all specific pruner implementations.

"""
abstract type AbstractPruner end

"""
    NoPruner

A struct representing a no-operation pruner. 
This pruner does not modify the branching table during the pruning process.

"""
struct NoPruner <: AbstractPruner end

"""
    prune(bt::BranchingTable, ::NoPruner, ::M, ::P, vs)

Applies a no-operation pruning strategy to the given branching table. 
This function serves as a placeholder for scenarios where no pruning is required.

# Arguments
- `bt::BranchingTable`: The branching table to be pruned.
- `::NoPruner`: An instance of NoPruner, indicating that no pruning will occur.
- `::M`: An abstract measure type, which is not utilized in this context.
- `::P`: An abstract problem type, which is not utilized in this context.
- `vs`: A vector of values associated with the branching process.

# Returns
- `bt`: The original branching table, unchanged.
"""
prune(bt::BranchingTable, ::NoPruner, ::M, ::P, vs) where{M<:AbstractMeasure, P<:AbstractProblem} = bt


"""
    BranchingStrategy

A struct representing an optimal branching strategy that utilizes various components for solving optimization problems.

# Fields
- `table_solver::TS`: An instance of a table solver, which is responsible for solving the underlying table representation of the problem.
- `set_cover_solver::SCS`: An instance of a set cover solver, which is used to solve the set covering problem.
- `pruner`: used as an input of `prune`, which takes a BranchingTable instance as the input and returns one with reduced size.
- `selector::SL`: An instance of a selector, which is responsible for selecting the next branching variable or decision.
- `measure::M`: An instance of a measure, which is used to evaluate the performance of the branching strategy.

"""
struct BranchingStrategy{TS<:AbstractTableSolver, SCS<:AbstractSetCoverSolver, PR<:AbstractPruner, SL<:AbstractSelector, M<:AbstractMeasure}
    table_solver::TS
    set_cover_solver::SCS
    pruner::PR
    selector::SL
    measure::M
end
Base.show(io::IO, strategy::BranchingStrategy) = print(io, 
"""
BranchingStrategy
    ├── table_solver - $(strategy.table_solver)
    ├── set_cover_solver - $(strategy.set_cover_solver)
    ├── pruner - $(strategy.pruner)
    ├── selector - $(strategy.selector)
    └── measure - $(strategy.measure)
""")

"""
    SolverConfig

A struct representing the configuration for a solver, including the reducer and branching strategy.

# Fields
- `reducer::R`: An instance of a reducer, which is responsible for reducing the problem size.
- `branching_strategy::BranchingStrategy`: An instance of a branching strategy, which guides the search process.
- `result_type::Type{TR}`: The type of the result that the solver will produce.

"""
struct SolverConfig{R<:AbstractReducer, B<:BranchingStrategy, TR}
    reducer::R
    branching_strategy::B
    result_type::Type{TR}
end
Base.show(io::IO, config::SolverConfig) = print(io, 
"""
SolverConfig
├── reducer - $(config.reducer) 
├── result_type - $(config.result_type)
└── branching_strategy - $(config.branching_strategy) 
""")

"""
    Branch the given problem using the specified solver configuration.

    # Arguments
    - `p::P`: The problem instance to branch.
    - `config::SolverConfig`: The configuration for the solver.

    # Returns
    The maximum result obtained from the branches.
"""
function reduce_and_branch(p::AbstractProblem, config::SolverConfig)
    rp, reducedvalue = reduce_problem(config.result_type, p, config.reducer)
    isempty(rp) && return reducedvalue

    strategy = config.branching_strategy
    variables = select(rp, strategy.measure, strategy.selector)  # select a subset of variables
    tbl = branching_table(rp, strategy.table_solver, variables)      # compute the BranchingTable
    pruned_tbl = prune(tbl, strategy.pruner, strategy.measure, rp, variables)
    rule = optimal_branching_rule(pruned_tbl, variables, rp, strategy.measure, strategy.set_cover_solver)
    return maximum(rule.branches) do branch
        subproblem, localvalue = apply_branch(rp, branch, variables)
        reduce_and_branch(subproblem, config) + localvalue + reducedvalue
    end
end