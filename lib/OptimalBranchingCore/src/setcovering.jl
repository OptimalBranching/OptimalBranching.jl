"""
    AbstractSetCoverSolver

An abstract type for the strategy of solving the set covering problem.
"""
abstract type AbstractSetCoverSolver end

"""
    LPSolver <: AbstractSetCoverSolver
    LPSolver(; max_itr::Int = 5, verbose::Bool = false)

A linear programming solver for set covering problems.

### Fields
- `max_itr::Int`: The maximum number of iterations to be performed.
- `verbose::Bool`: Whether to print the solver's output.
"""
Base.@kwdef struct LPSolver <: AbstractSetCoverSolver 
    max_itr::Int = 5
    verbose::Bool = false
end

"""
    IPSolver <: AbstractSetCoverSolver
    IPSolver(; max_itr::Int = 5, verbose::Bool = false)

An integer programming solver for set covering problems.

### Fields
- `max_itr::Int`: The maximum number of iterations to be performed.
- `verbose::Bool`: Whether to print the solver's output.
"""
Base.@kwdef struct IPSolver <: AbstractSetCoverSolver 
    max_itr::Int = 5
    verbose::Bool = false
end

"""
    CandidateClause{INT <: Integer}

A candidate clause is a clause containing the formation related to how it can cover the items in the branching table.

### Fields
- `covered_items::Set{Int}`: The items in the branching table that are covered by the clause.
- `clause::Clause{INT}`: The clause itself.
"""
struct CandidateClause{INT <: Integer}
    covered_items::Set{Int}
    clause::Clause{INT}
end
CandidateClause(covered_items::Vector{Int}, clause::Clause) = CandidateClause(Set(covered_items), clause)

Base.show(io::IO, sc::CandidateClause{INT}) where INT = print(io, "CandidateClause{$INT}: covered_items: $(sort([i for i in sc.covered_items])), clause: $(sc.clause)")
Base.:(==)(sc1::CandidateClause{INT}, sc2::CandidateClause{INT}) where {INT} = (sc1.covered_items == sc2.covered_items) && (sc1.clause == sc2.clause)

"""
    complexity_bv(branching_vector::Vector)::Float64

Calculates the complexity that associated with the provided branching vector by solving the equation:
```math
γ^0 = \\sum_{δρ \\in \\text{branching_vector}} γ^{-δρ}
```

### Arguments
- `branching_vector`: a vector of problem size reductions in the branches.

### Returns
- `Float64`: The computed γ value.
"""
function complexity_bv(branching_vector::Vector{T}) where {T}
    # NOTE: for different measure, the size reduction may not always be positive
    if any(x -> x <= 0, branching_vector)
        return Inf
    end
    f = x -> sum(x[1]^(-i) for i in branching_vector) - 1.0
    return bisect_solve(f, 1.0, f(1.0), 2.0, f(2.0))
end
function bisect_solve(f, a, fa, b, fb)
    @assert fa * fb <= 0 "f(a) and f(b) have the same sign"
    while b - a > eps(b)
        c = (a + b) / 2
        fc = f(c)
        if fc == 0
            return c
        elseif fa * fc < 0
            b = c
        else
            a = c
        end
    end
    return (a + b) / 2
end

"""
    minimize_γ(candidate_clauses::AbstractVector{CandidateClause{INT}}, Δρ::Vector{TF}, solver) where{INT, TF}

Finds the optimal cover based on the provided vector of problem size reduction.
This function implements a cover selection algorithm using an iterative process.
It utilizes an integer programming solver to optimize the selection of sub-covers based on their complexity.

### Arguments
- `candidate_clauses::AbstractVector{CandidateClause{INT}}`: A vector of CandidateClause structures.
- `Δρ::Vector{TF}`: A vector of problem size reduction for each CandidateClause.
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.

### Keyword Arguments
- `γ0::Float64`: The initial γ value.

### Returns
A tuple of two elements: (indices of selected clauses, γ)
"""
function minimize_γ(num_items::Int, candidate_clauses::AbstractVector{CandidateClause{INT}}, Δρ::Vector{TF}, solver::AbstractSetCoverSolver; γ0::Float64 = 2.0) where{INT, TF}
    @debug "solver = $(solver), sets = $(candidate_clauses), γ0 = $γ0"

    # Note: the following instance is captured for time saving, and also for it may cause IP solver to fail
    for (k, clause) in enumerate(candidate_clauses)
        (length(clause.covered_items) == num_items) && return [k], 1.0
    end

    cx_old = cx = γ0
    local picked_scs
    for i = 1:solver.max_itr
        weights = 1 ./ cx_old .^ Δρ
        picked_scs = weighted_minimum_set_cover(solver, weights, candidate_clauses, num_items)
        cx = complexity_bv(Δρ[picked_scs])
        @debug "Iteration $i, picked indices = $(picked_scs), clauses = $(candidate_clauses[picked_scs]), branching_vector = $(Δρ[picked_scs]), γ = $cx"
        cx ≈ cx_old && break  # convergence
        cx_old = cx
    end
    return picked_scs, cx
end

"""
    weighted_minimum_set_cover(solver, weights::AbstractVector, candidate_clauses::AbstractVector{CandidateClause{INT}}, num_items::Int) where{INT, TF, T}

Solves the weighted minimum set cover problem.

### Arguments
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.
- `weights::AbstractVector`: The weights of the candidate clauses.
- `candidate_clauses::AbstractVector{CandidateClause{INT}}`: A vector of CandidateClause structures.
- `num_items::Int`: The number of elements to cover.

### Returns
A vector of indices of selected clauses.
"""
function weighted_minimum_set_cover(solver::LPSolver, weights::AbstractVector, candidate_clauses::AbstractVector{CandidateClause{INT}}, num_items::Int) where{INT}
    nsc = length(candidate_clauses)

    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:nsc
        for j in candidate_clauses[i].covered_items
            push!(sets_id[j], i)
        end
    end

    # LP by JuMP
    model = Model(HiGHS.Optimizer)
    !solver.verbose && set_silent(model)
    @variable(model, 0 <= x[i = 1:nsc] <= 1)
    @objective(model, Min, sum(x[i] * weights[i] for i in 1:nsc))
    for i in 1:num_items
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)
    return pick_sets(value.(x), candidate_clauses, num_items)
end

function weighted_minimum_set_cover(solver::IPSolver, weights::AbstractVector, candidate_clauses::AbstractVector{CandidateClause{INT}}, num_items::Int) where{INT}
    nsc = length(candidate_clauses)

    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:nsc
        for j in candidate_clauses[i].covered_items
            push!(sets_id[j], i)
        end
    end

    # IP by JuMP
    model = Model(SCIP.Optimizer)
    !solver.verbose && set_attribute(model, "display/verblevel", 0)
    set_attribute(model, "limits/gap", 0.05)

    @variable(model, 0 <= x[i = 1:nsc] <= 1, Int)
    @objective(model, Min, sum(x[i] * weights[i] for i in 1:nsc))
    for i in 1:num_items
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)
    return pick_sets(value.(x), candidate_clauses, num_items)
end

# by viewing xs as the probability of being selected, we can use a random algorithm to pick the sets
function pick_sets(xs::Vector{TF}, candidate_clauses::AbstractVector{CandidateClause{INT}}, num_items::Int) where{INT, TF}
    picked = Set{Int}()
    picked_ids = Set{Int}()
    nsc = length(candidate_clauses)
    flag = true
    while flag 
        for i in 1:nsc
            if (rand() < xs[i]) && i ∉ picked
                push!(picked, i)
                picked_ids = union(picked_ids, candidate_clauses[i].covered_items)
            end
            if length(picked_ids) == num_items
                flag = false
                break
            end
        end
    end

    return [i for i in picked]
end
