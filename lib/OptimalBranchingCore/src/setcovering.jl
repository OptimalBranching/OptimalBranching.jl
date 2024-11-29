"""
    complexity(branching_vector::Vector{T}) where {T}

Calculates the complexity based on the provided branching vector by solving the equation:
```math
x^0 = \\sum_{δρ \\in \\text{branching_vector}} x^{-δρ}
```

# Arguments
- `branching_vector::Vector{T}`: a vector of problem size reduction.

# Returns
- `Float64`: The computed complexity value.
"""
function complexity(branching_vector::Vector{T}) where {T}
    f = x -> sum(x[1]^(-i) for i in branching_vector) - 1.0
    sol = nlsolve(f, [1.0])
    return sol.zero[1]
end

function γ0(num_items::Int, sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}) where{INT, TF}
    max_dict = Dict([i => 0 for i in 1:num_items])
    for (i, sub_cover) in enumerate(sub_covers)
        length(sub_cover.ids) == 1 || continue  # ??? What about having two sets
        id = first(sub_cover.ids)
        max_dict[id] = max(max_dict[id], Δρ[i])
    end
    max_rvs = [max_dict[i] for i in 1:num_items]
    return complexity(max_rvs)
end

"""
    branching_vector(p::AbstractProblem, m::AbstractMeasure, vs::Vector{T}) where T

Generate the branching vector give a target problem and measure.

- `p::AbstractProblem`: An instance of a problem that needs to be solved.
- `m::AbstractMeasure`: An instance of a measure associated with the problem.
- `vs::Vector{T}`: A vector of values used in the calculation.
"""
function branching_vector(p::AbstractProblem, sub_covers, m::AbstractMeasure, vs::Vector{T}) where T
    return [measure(p, m) - measure(apply_branch(p, subcover.clause, vs), m) for subcover in sub_covers]
end

"""
    minimize_γ(sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}, solver) where{INT, TF}

Finds the optimal cover based on the provided vector of problem size reduction.
This function implements a cover selection algorithm using an iterative process.
It utilizes an integer programming solver to optimize the selection of sub-covers based on their complexity.

# Arguments
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `Δρ::Vector{TF}`: A vector of problem size reduction for each subcover.
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.

# Returns
A tuple containing:
- A vector of selected subcovers.
- The minimum ``γ`` value.
"""
function minimize_γ(num_items::Int, sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}, solver) where{INT, TF}
    max_itr = solver.max_itr
    cx = γ0(num_items, sub_covers, Δρ)
    @debug "solver = $(solver), sets = $(sub_covers), γ0 = $(cx)"

    for sub_cover in sub_covers  # check if there is a subcover that covers all elements
        (length(sub_cover.ids) == num_items) && return [sub_cover], 1.0
    end

    cx_old = cx
    local picked
    for i = 1:max_itr
        weights = 1 ./ cx_old .^ Δρ
        xs = weighted_minimum_set_cover(solver, weights, sub_covers, num_items)
        picked_scs = pick_sets(xs, sub_covers, num_items)
        picked = sub_covers[picked_scs]
        cx = complexity(Δρ[picked_scs])
        @debug "Iteration $i, xs = $(xs), picked = $(picked), branching_vector = $(Δρ[picked_scs]), complexity = $cx"
        cx ≈ cx_old && break  # convergence
        cx_old = cx
    end
    return picked, cx
end

"""
    weighted_minimum_set_cover(solver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, num_items::Int) where{INT, TF, T}

Solves the weighted minimum set cover problem.

# Arguments
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.
- `weights::AbstractVector`: The weights of the subcovers.
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `num_items::Int`: The number of elements to cover.
"""
function weighted_minimum_set_cover(solver::LPSolver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, num_items::Int) where{INT}
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:nsc
        for j in sub_covers[i].ids
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

    return [value(x[i]) for i in 1:nsc]
end

function weighted_minimum_set_cover(solver::IPSolver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, num_items::Int) where{INT}
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:nsc
        for j in sub_covers[i].ids
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

    selected = [value(x[i]) for i in 1:nsc]

    return selected
end

# by viewing xs as the probability of being selected, we can use a random algorithm to pick the sets
function pick_sets(xs::Vector{TF}, sub_covers::AbstractVector{SubCover{INT}}, num_items::Int) where{INT, TF}
    picked = Set{Int}()
    picked_ids = Set{Int}()
    nsc = length(sub_covers)
    flag = true
    while flag 
        for i in 1:nsc
            if (rand() < xs[i]) && i ∉ picked
                push!(picked, i)
                picked_ids = union(picked_ids, sub_covers[i].ids)
            end
            if length(picked_ids) == num_items
                flag = false
                break
            end
        end
    end

    return [i for i in picked]
end

