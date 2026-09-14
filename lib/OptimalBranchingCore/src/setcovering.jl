"""
    AbstractSetCoverSolver

An abstract type for the strategy of solving the set covering problem.
"""
abstract type AbstractSetCoverSolver end

"""
    LPSolver <: AbstractSetCoverSolver
    LPSolver(; optimizer = HiGHS.Optimizer, max_itr::Int = 20, γ0::Float64 = 2.0, verbose::Bool = false)

A linear programming solver for set covering problems.

### Fields
- `optimizer`: The optimizer to be used.
- `max_itr::Int`: The maximum number of iterations to be performed.
- `γ0::Float64`: The initial γ value.
- `verbose::Bool`: Whether to print the solver's output.
"""
Base.@kwdef struct LPSolver <: AbstractSetCoverSolver 
    optimizer = HiGHS.Optimizer
    max_itr::Int = 20
    γ0::Float64 = 2.0
    verbose::Bool = false
end

"""
    IPSolver <: AbstractSetCoverSolver
    IPSolver(; optimizer = HiGHS.Optimizer, max_itr::Int = 20, γ0::Float64 = 2.0, verbose::Bool = false)

An integer programming solver for set covering problems.

### Fields
- `optimizer`: The optimizer to be used.
- `max_itr::Int`: The maximum number of iterations to be performed.
- `γ0::Float64`: The initial γ value.
- `verbose::Bool`: Whether to print the solver's output.
"""
Base.@kwdef struct IPSolver <: AbstractSetCoverSolver 
    optimizer = HiGHS.Optimizer
    max_itr::Int = 20
    γ0::Float64 = 2.0
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
    iszero(fa * fb) && return iszero(fa) ? a : b
    @assert fa * fb <= 0 "f(a) and f(b) have the same sign, a = $a, b = $b, fa = $fa, fb = $fb"
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
    OptimalBranchingResult{INT <: Integer}

The result type for the optimal branching rule.

### Fields
- `optimal_rule::DNF{INT}`: The optimal branching rule.
- `branching_vector::Vector{T<:Real}`: The branching vector that records the size reduction in each subproblem.
- `γ::Float64`: The optimal γ value (the complexity of the branching rule).
"""
struct OptimalBranchingResult{INT <: Integer, T <: Real}
    optimal_rule::DNF{INT}
    branching_vector::Vector{T}
    γ::Float64
end
Base.show(io::IO, results::OptimalBranchingResult{INT, T}) where {INT, T} = print(io, "OptimalBranchingResult{$INT, $T}:\n optimal_rule: $(results.optimal_rule)\n branching_vector: $(results.branching_vector)\n γ: $(results.γ)")
get_clauses(results::OptimalBranchingResult) = results.optimal_rule.clauses
get_clauses(res::AbstractArray) = res

"""
    minimize_γ(table::BranchingTable, candidates::Vector{Clause}, Δρ::Vector, solver)

Finds the optimal cover based on the provided vector of problem size reduction.
This function implements a cover selection algorithm using an iterative process.
It utilizes an integer programming solver to optimize the selection of sub-covers based on their complexity.

### Arguments
- `table::BranchingTable`: A branching table containing clauses that need to be covered, a table entry is covered by a clause if one of its bit strings satisfies the clause. Please refer to [`covered_by`](@ref) for more details.
- `candidates::Vector{Clause}`: A vector of candidate clauses to form the branching rule (in the form of [`DNF`](@ref)).
- `Δρ::Vector`: A vector of problem size reduction for each candidate clause.
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.

### Returns
A tuple of two elements: (indices of selected subsets, γ)
"""
function minimize_γ(table::BranchingTable, candidates::Vector{Clause{INT}}, Δρ::Vector, solver::AbstractSetCoverSolver) where {INT}
    subsets = [covered_items(table.table, c) for c in candidates]
    @debug "solver = $(solver), subsets = $(subsets), γ0 = $(solver.γ0), Δρ = $(Δρ)"
    num_items = length(table.table)
    subsets, Δρ, picked_items = eliminate_strictly_worse_subsets(subsets, Δρ)
    candidates = candidates[picked_items]

    # Note: the following instance is captured for time saving, and also for it may cause IP solver to fail
    for (k, subset) in enumerate(subsets)
        (length(subset) == num_items) && return OptimalBranchingResult(DNF([candidates[k]]), [Δρ[k]], 1.0)
    end

    cx_old = cx = solver.γ0
    local picked_scs
    for i = 1:solver.max_itr
        weights = 1 ./ cx_old .^ Δρ
        picked_scs = weighted_minimum_set_cover(solver, weights, subsets, num_items)
        cx = complexity_bv(Δρ[picked_scs])
        @debug "Iteration $i, picked indices = $(picked_scs), subsets = $(subsets[picked_scs]), branching_vector = $(Δρ[picked_scs]), γ = $cx"
        cx ≈ cx_old && break  # convergence
        cx_old = cx
    end
    return OptimalBranchingResult(DNF([candidates[i] for i in picked_scs]), Δρ[picked_scs], cx)
end

function eliminate_strictly_worse_subsets(subsets::Vector{Vector{Int}}, Δρ::Vector)
    # eliminated strictly worse subsets
    mask = trues(length(subsets))
    dict = Dict{Vector{Int}, Tuple{Int, eltype(Δρ)}}()
    for i in 1:length(subsets)
        set = subsets[i]
        if haskey(dict, set)
            idx_pre, Δρ_pre = dict[set]
            if Δρ[i] <= Δρ_pre
                mask[i] = false
            else
                mask[idx_pre] = false
                dict[set] = (i, Δρ[i])
            end
        else
            dict[set] = (i, Δρ[i])
        end
    end
    picked_items = findall(mask)
    return subsets[picked_items], Δρ[picked_items], picked_items
end

# try to find a non-zero intersection of clauses in the branching table
# strategy: :dfs (depth-first search) or :bfs (breadth-first search), dfs gives the first found non-zero intersection, which covers the whole branching table, bfs gives the optimal result
function intersect_clauses(tbl::BranchingTable{INT}, strategy::Symbol) where {INT}
    n, bss = tbl.bit_length, tbl.table
    tbl_clauses = [[Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)] for bs in bss]
    length(tbl_clauses) == 1 && return tbl_clauses[1]
    sort!(tbl_clauses, by = x -> length(x))

    if strategy == :dfs
        for c0 in tbl_clauses[1]
            c_res = _intersect_clauses_dfs((@view tbl_clauses[2:end]), c0, n)
            c_res.mask != 0 && return [c_res]
        end

        # not found any non-zero intersection
        return Clause{INT}[]
    elseif strategy == :bfs
        c0s = _intersect_clauses_bfs((@view tbl_clauses[2:end]), tbl_clauses[1], n)
        return c0s
    else 
        error("Invalid strategy: $strategy, must be :dfs or :bfs")
    end
end

# try to find a group of bits sharing the same value through all the clauses in the branching table
# if there are two groups with opposite values, return the two groups
# strategy: :dfs (depth-first search) or :bfs (breadth-first search), dfs gives the first found folding group, which covers the whole branching table, bfs gives the optimal result, which has the largest length.
function folding_clauses(tbl::BranchingTable{INT}, strategy::Symbol) where {INT}
    n, bss = tbl.bit_length, tbl.table
    tbl_clauses = [union([Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)], [Clause(bmask(INT, 1:n), ~bs[i]) for i in 1:length(bs)]) for bs in bss]
    length(tbl_clauses) == 1 && return tbl_clauses[1]
    sort!(tbl_clauses, by = x -> length(x))

    if strategy == :dfs
        for c0 in tbl_clauses[1]
            c_res = _folding_clauses_dfs((@view tbl_clauses[2:end]), c0, n)
            c_res.mask != 0 && return [c_res]
        end

        # not found any non-zero intersection
        return Clause{INT}[]
    elseif strategy == :bfs
        c0s = _folding_clauses_bfs((@view tbl_clauses[2:end]), tbl_clauses[1], n)
        return c0s
    else 
        error("Invalid strategy: $strategy, must be :dfs or :bfs")
    end
end

function _folding_clauses_dfs(tbl_clauses::AbstractVector{Vector{Clause{INT}}}, c0::Clause{INT}, n::Int) where {INT}
    flag = (length(tbl_clauses) == 1) # flag is true if reaching the last layer
    for ci in tbl_clauses[1]
        c_new = gather2(n, c0, ci)
        if count_ones(c_new.mask) > 1 && count_ones(c_new.val) > 1 # skip the clause including less than 2 value-1 bits
            flag && (return c_new) # return the final result if reaching the last layer
            c_res = _folding_clauses_dfs((@view tbl_clauses[2:end]), c_new, n) # not the last layer, continue
            (count_ones(c_res.mask) > 1 && count_ones(c_res.val) > 1) && return c_res # return the result if the number of value-1 bits is greater than 1, stops the recursion
        end
    end
    return Clause(bmask(INT, 0), bmask(INT, 0))
end

function _folding_clauses_bfs(tbl_clauses::AbstractVector{Vector{Clause{INT}}}, cs::Vector{Clause{INT}}, n::Int) where {INT}
    new_cs = Vector{Clause{INT}}()
    for ci in tbl_clauses[1]
        for cj in cs
            c_new = gather2(n, cj, ci)
            (count_ones(c_new.mask) > 1 && count_ones(c_new.val) > 1) && push!(new_cs, c_new)
        end
    end
    unique!(new_cs)
    return (length(tbl_clauses) == 1 || isempty(new_cs)) ? new_cs : _folding_clauses_bfs((@view tbl_clauses[2:end]), new_cs, n)
end

function _intersect_clauses_dfs(tbl_clauses::AbstractVector{Vector{Clause{INT}}}, c0::Clause{INT}, n::Int) where {INT}
    flag = (length(tbl_clauses) == 1) # flag is true if reaching the last layer
    for ci in tbl_clauses[1]
        c_new = gather2(n, c0, ci)
        if c_new.mask != 0 # skip the zero clause in middle layers
            flag && (return c_new) # return the final result if reaching the last layer
            c_res = _intersect_clauses_dfs((@view tbl_clauses[2:end]), c_new, n) # not the last layer, continue to intersect
            (c_res.mask != 0) && return c_res # return the result if the intersection is non-zero, stops the recursion
        end
    end
    return Clause(bmask(INT, 0), bmask(INT, 0))
end

function _intersect_clauses_bfs(tbl_clauses::AbstractVector{Vector{Clause{INT}}}, cs::Vector{Clause{INT}}, n::Int) where {INT}
    new_cs = Vector{Clause{INT}}()
    for ci in tbl_clauses[1]
        for cj in cs
            c_new = gather2(n, cj, ci)
            (c_new.mask != 0) && push!(new_cs, c_new)
        end
    end
    unique!(new_cs)
    return (length(tbl_clauses) == 1 || isempty(new_cs)) ? new_cs : _intersect_clauses_bfs((@view tbl_clauses[2:end]), new_cs, n)
end

# TODO: we need to extend this function to trim the candidate clauses
"""
    candidate_clauses(tbl::BranchingTable{INT}) where {INT}

Generates candidate clauses from a branching table.

### Arguments
- `tbl::BranchingTable{INT}`: The branching table containing bit strings.

### Returns
- `Vector{Clause{INT}}`: A vector of `Clause` objects generated from the branching table.
"""
function candidate_clauses(tbl::BranchingTable{INT}) where {INT}
    n, bss = tbl.bit_length, tbl.table
    bs = reduce(vcat, bss)
    all_clauses = Dict{Clause{INT}, Bool}()
    temp_clauses = [Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)]
    while !isempty(temp_clauses)
        c = pop!(temp_clauses)
        haskey(all_clauses, c) && continue
        all_clauses[c] = true
        for i in 1:length(bss)
            if !any(x->covered_by(x, c), bss[i])
                for b in bss[i]
                    # include a bitstring not covered by c to create a new clause
                    c_new = gather2(n, c, Clause(bmask(INT, 1:n), b))
                    if (c_new != c) && c_new.mask != 0
                        push!(temp_clauses, c_new)
                    end
                end
            end
        end
    end
    return collect(keys(all_clauses))
end
# Returns the indices of the bit strings that are covered by the clause.
function covered_items(bitstrings, clause::Clause)
    return findall(bs -> any(x->covered_by(x, clause), bs), bitstrings)
end
# merge two clauses, i.e. generate a new clause covering both
function gather2(n::Int, c1::Clause{INT}, c2::Clause{INT}) where INT
    b1 = c1.val & c1.mask
    b2 = c2.val & c2.mask
    mask = (b1 ⊻ flip_all(n, b2)) & c1.mask & c2.mask
    val = b1 & mask
    return Clause(mask, val)
end

function is_solved_by(xs::Vector{T}, sets_id::Vector{Vector{Int}}, num_items::Int) where{T}
    for i in 1:num_items
        flag = sum(xs[j] for j in sets_id[i])
        ((flag < 1) && !(flag ≈ 1)) && return false
    end
    return true
end

"""
    weighted_minimum_set_cover(solver, weights::AbstractVector, subsets::Vector{Vector{Int}}, num_items::Int)

Solves the weighted minimum set cover problem.

### Arguments
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.
- `weights::AbstractVector`: The weights of the subsets.
- `subsets::Vector{Vector{Int}}`: A vector of subsets.
- `num_items::Int`: The number of elements to cover.

### Returns
A vector of indices of selected subsets.
"""
function weighted_minimum_set_cover(solver::Union{LPSolver, IPSolver}, weights::AbstractVector, subsets::Vector{Vector{Int}}, num_items::Int)
    nsc = length(subsets)
    sets_id = _init_set_id(subsets, num_items)

    # LP by JuMP
    model = Model(solver.optimizer)
    !solver.verbose && set_silent(model)
    if solver isa LPSolver
        @variable(model, 0 <= x[i = 1:nsc] <= 1)
    elseif solver isa IPSolver
        @variable(model, 0 <= x[i = 1:nsc] <= 1, Int)
    end
    @objective(model, Min, sum(x[i] * weights[i] for i in 1:nsc))
    for i in 1:num_items
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)
    return pick_sets(value.(x), subsets, num_items)
end
function _init_set_id(subsets::Vector{Vector{Int}}, num_items::Int)
    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:length(subsets)
        for j in subsets[i]
            push!(sets_id[j], i)
        end
    end
    return sets_id
end

# by viewing xs as the probability of being selected, we can use a random algorithm to pick the sets
function pick_sets(xs::Vector, subsets::Vector{Vector{Int}}, num_items::Int)
    picked = Set{Int}()
    picked_ids = Set{Int}()
    nsc = length(subsets)
    flag = true
    while flag 
        for i in 1:nsc
            if (rand() < xs[i]) && i ∉ picked
                push!(picked, i)
                picked_ids = union(picked_ids, subsets[i])
            end
            if length(picked_ids) == num_items
                flag = false
                break
            end
        end
    end

    return [i for i in picked]
end

"""
    weighted_minimum_signed_exact_cover(solver, weights::AbstractVector, subsets::Vector{Vector{Int}}, num_items::Int, cmax::Float64)

Solves the weighted minimum signed exact cover problem. It is different from the unbalanced version in that the variables are now changed to a real variable rather than a binary variable.
It represents how many times a subset is selected. This number can be positive, zero, or negative. The total number of times a subset is selected must be equal to one.

### Arguments
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.
- `weights::AbstractVector`: The weights of the subsets.
- `subsets::Vector{Vector{Int}}`: A vector of subsets.
- `num_items::Int`: The number of elements to cover.
- `cmax::Float64`: The maximum coefficient of the subsets.

### Returns
A vector of weights for each subset.
"""
function weighted_minimum_signed_exact_cover(solver::Union{LPSolver, IPSolver}, weights::AbstractVector, subsets::Vector{Vector{Int}}, num_items::Int, cmax::Float64)
    nsc = length(subsets)
    sets_id = _init_set_id(subsets, num_items)

    # IP by JuMP
    model = Model(solver.optimizer)
    !solver.verbose && set_silent(model)
    if solver isa LPSolver
        @variable(model, 0 <= x[i = 1:nsc] <= 1)
    elseif solver isa IPSolver
        @variable(model, 0 <= x[i = 1:nsc] <= 1, Int)
    end
    @variable(model, c[i = 1:nsc])          # coefficient of the i-th subset
    @objective(model, Min, sum(x[i] * weights[i] for i in 1:nsc))
    for i in 1:num_items  # cover all items exactly once
        @constraint(model, sum(c[j] for j in sets_id[i]) == 1)
    end
    for i in 1:nsc
        # inspired by: https://ieeexplore.ieee.org/document/6638790
        @constraint(model, c[i] >= -cmax * x[i])
        @constraint(model, c[i] <= cmax * x[i])
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)
    return value.(c)
end