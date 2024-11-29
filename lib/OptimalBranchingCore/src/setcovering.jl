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

function max_id(sub_covers::AbstractVector{SubCover{INT}}) where{INT}
    m0 = 1
    for sc in sub_covers
        m0 = max(m0, maximum(sc.ids))
    end
    return m0
end

function γ0(n::Int, sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}) where{INT, TF}
    max_dict = Dict([i => 0 for i in 1:n])
    for (i, sub_cover) in enumerate(sub_covers)
        length(sub_cover.ids) == 1 || continue
        id = first(sub_cover.ids)
        max_dict[id] = max(max_dict[id], Δρ[i])
    end
    max_rvs = [max_dict[i] for i in 1:n]
    return complexity(max_rvs)
end

"""
    minimum_γ(sub_covers::AbstractVector{SubCover{INT}}, p::AbstractProblem, m::AbstractMeasure, vs::Vector{T}, solver::Union{LPSolver, IPSolver}) where{INT, T}

Calculates the optimal cover from the provided subcovers using a specified solver.

# Arguments
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `p::AbstractProblem`: An instance of a problem that needs to be solved.
- `m::AbstractMeasure`: An instance of a measure associated with the problem.
- `vs::Vector{T}`: A vector of values used in the calculation.
- `solver::Union{LPSolver, IPSolver}`: The solver to be used for optimization.

# Returns
- A tuple containing:
  - A vector of selected subcovers.
  - The computed complexity value.

# Description
This function computes the difference in measure for each subcover and then calls another `cover` function to find the optimal cover based on the computed differences.
"""
function minimum_γ(sub_covers::AbstractVector{SubCover{INT}}, p::AbstractProblem, m::AbstractMeasure, vs::Vector{T}, solver::Union{LPSolver, IPSolver}) where{INT, T}
    # compute the problem size reduction for each subcover
    Δρ = [measure(p, m) - measure(apply(p, subcover.clause, vs), m) for subcover in sub_covers]
    return minimum_γ(sub_covers, Δρ, solver)
end

"""
    minimum_γ(sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}, solver) where{INT, TF}

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
function minimum_γ(sub_covers::AbstractVector{SubCover{INT}}, Δρ::Vector{TF}, solver) where{INT, TF}
    max_itr = solver.max_itr
    n = max_id(sub_covers)
    cx = γ0(n, sub_covers, Δρ)
    @debug "solver = $(solver), sets = $(sub_covers), γ0 = $(cx)"

    for sub_cover in sub_covers  # check if there is a subcover that covers all elements
        (length(sub_cover.ids) == n) && return [sub_cover], 1.0
    end

    cx_old = cx
    for i = 1:max_itr
        weights = 1 ./ cx_old .^ Δρ
        xs = weighted_minimum_set_cover(solver, weights, sub_covers, n)
        picked_scs = pick_sets(xs, sub_covers, n)
        picked = sub_covers[picked_scs]
        cx = complexity(Δρ[picked_scs])
        @debug "Iteration $i, xs = $(xs), picked = $(picked), branching_vector = $(Δρ[picked_scs]), complexity = $cx"
        cx ≈ cx_old && break  # convergence
        cx_old = cx
    end
    return picked, cx
end

"""
    weighted_minimum_set_cover(solver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, n::Int, Δρ::Vector{T}) where{INT, TF, T}

Solves the weighted minimum set cover problem.

# Arguments
- `solver`: The solver to be used. It can be an instance of `LPSolver` or `IPSolver`.
- `weights::AbstractVector`: The weights of the subcovers.
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `n::Int`: The number of elements to cover.
"""
function weighted_minimum_set_cover(solver::LPSolver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, n::Int) where{INT, TF}
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:n]
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
    for i in 1:n
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)

    return [value(x[i]) for i in 1:nsc]
end

function weighted_minimum_set_cover(solver::IPSolver, weights::AbstractVector, sub_covers::AbstractVector{SubCover{INT}}, n::Int) where{INT, TF}
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:n]
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
    for i in 1:n
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)

    selected = [value(x[i]) for i in 1:nsc]

    return selected
end

# by viewing xs as the probability of being selected, we can use a random algorithm to pick the sets
function pick_sets(xs::Vector{TF}, sub_covers::AbstractVector{SubCover{INT}}, n::Int) where{INT, TF}
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
            if length(picked_ids) == n
                flag = false
                break
            end
        end
    end

    return [i for i in picked]
end

