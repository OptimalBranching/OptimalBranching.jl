"""
    complexity(sbranches::Vector{T}) where {T}

Calculates the complexity based on the provided branching structures.

# Arguments
- `sbranches::Vector{T}`: A vector of branching structures, where each element represents a branch.

# Returns
- `Float64`: The computed complexity value.

"""
function complexity(sbranches::Vector{T}) where {T}
    f = x -> sum(x[1]^(-i) for i in sbranches) - 1.0
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

function γ0(sub_covers::AbstractVector{SubCover{INT}}, dns::Vector{TF}) where{INT, TF}
    n = max_id(sub_covers)
    max_dict = Dict([i => 0 for i in 1:n])
    for (i, sub_cover) in enumerate(sub_covers)
        length(sub_cover.ids) == 1 || continue
        id = first(sub_cover.ids)
        max_dict[id] = max(max_dict[id], dns[i])
    end

    max_rvs = [max_dict[i] for i in 1:n]

    return complexity(max_rvs), n
end

function dn(p::P, m::M, subcover::SubCover{INT}, vs::Vector{T}) where{P<:AbstractProblem, M<:AbstractMeasure, INT<:Integer, T}
    return measure(p, m) - measure(apply(p, subcover.clause, vs), m)
end

"""
    cover(sub_covers::AbstractVector{SubCover{INT}}, p::P, m::M, vs::Vector{T}, solver::Union{LPSolver, IPSolver}; verbose::Bool = false) where{INT, P<:AbstractProblem, M<:AbstractMeasure, T}

Calculates the optimal cover from the provided subcovers using a specified solver.

# Arguments
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `p::P`: An instance of a problem that needs to be solved.
- `m::M`: An instance of a measure associated with the problem.
- `vs::Vector{T}`: A vector of values used in the calculation.
- `solver::Union{LPSolver, IPSolver}`: The solver to be used for optimization.
- `verbose::Bool`: A flag to enable verbose output (default is false).

# Returns
- A tuple containing:
  - A vector of selected subcovers.
  - The computed complexity value.

# Description
This function computes the difference in measure for each subcover and then calls another `cover` function to find the optimal cover based on the computed differences.
"""
function cover(sub_covers::AbstractVector{SubCover{INT}}, p::P, m::M, vs::Vector{T}, solver::Union{LPSolver, IPSolver}; verbose::Bool = false) where{INT, P<:AbstractProblem, M<:AbstractMeasure, T}
    dns = [dn(p, m, subcover, vs) for subcover in sub_covers]
    return cover(sub_covers, dns, solver; verbose)
end

"""
    cover(sub_covers::AbstractVector{SubCover{INT}}, dns::Vector{TF}, solver::LPSolver; verbose::Bool = false) where{INT, TF}

Finds the optimal cover based on the provided differences in measure.

# Arguments
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of subcover structures.
- `dns::Vector{TF}`: A vector of differences in measure for each subcover.
- `solver::LPSolver`: The linear programming solver to be used.
- `verbose::Bool`: A flag to enable verbose output (default is false).

# Returns
- A tuple containing:
  - A vector of selected subcovers.
  - The computed complexity value.

# Description
This function iteratively solves the linear programming problem to find the optimal cover, updating the complexity value until convergence or the maximum number of iterations is reached.

"""
function cover(sub_covers::AbstractVector{SubCover{INT}}, dns::Vector{TF}, solver::LPSolver; verbose::Bool = false) where{INT, TF}
    max_itr = solver.max_itr
    cx, n = γ0(sub_covers, dns)
    verbose && (@info "γ0 = $(cx)")
    scs_new = copy(sub_covers)
    cx_old = cx
    for i = 1:max_itr
        xs = LP_setcover(cx, scs_new, n, dns, verbose)
        picked_scs = random_pick(xs, sub_covers, n)
        cx = complexity(dns[picked_scs])
        picked = sub_covers[picked_scs]
        verbose && (@info "LP Solver, Iteration $i, complexity = $cx")
        if (i == max_itr) || (cx ≈ cx_old)
            return picked, cx
        else
            cx_old = cx
        end
    end
end


function LP_setcover(γp::TF, sub_covers::AbstractVector{SubCover{INT}}, n::Int, dns::Vector{T}, verbose::Bool) where{INT, TF, T}
    fixeds = dns
    γs = 1 ./ γp .^ fixeds
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:n]
    for i in 1:nsc
        for j in sub_covers[i].ids
            push!(sets_id[j], i)
        end
    end

    # LP by JuMP
    model = Model(HiGHS.Optimizer)
    !verbose && set_silent(model)
    @variable(model, 0 <= x[i = 1:nsc] <= 1)
    @objective(model, Min, sum(x[i] * γs[i] for i in 1:nsc))
    for i in 1:n
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)

    return [value(x[i]) for i in 1:nsc]
end

function random_pick(xs::Vector{TF}, sub_covers::AbstractVector{SubCover{INT}}, n::Int) where{INT, TF}
    picked = Set{Int}()
    picked_ids = Set{Int}()
    nsc = length(sub_covers)
    flag = true
    while flag 
        for i in 1:nsc
            if (rand() < xs[i]) && !(i in picked)
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

function pick(xs::Vector{TF}, sub_covers::AbstractVector{SubCover{INT}}) where{INT, TF}
    return [sub_covers[i] for i in 1:length(xs) if xs[i] ≈ 1.0]
end

"""
    cover(sub_covers::AbstractVector{SubCover{INT}}, dns::Vector{TF}, solver::IPSolver; verbose::Bool = false) where{INT, TF}

This function implements a cover selection algorithm using an iterative process. It utilizes an integer programming solver to optimize the selection of sub-covers based on their complexity.

# Arguments
- `sub_covers::AbstractVector{SubCover{INT}}`: A vector of sub-cover objects that represent the available covers.
- `dns::Vector{TF}`: A vector of decision variables or parameters that influence the complexity calculation.
- `solver::IPSolver`: An object that contains the settings for the integer programming solver, including the maximum number of iterations.
- `verbose::Bool`: A flag to control the verbosity of the output. If set to true, additional information will be logged.

# Returns
- A tuple containing:
  - `picked`: A vector of selected sub-covers based on the optimization process.
  - `cx`: The final complexity value after the optimization iterations.

# Description
This function iteratively solves the integer programming problem to find the optimal cover, updating the complexity value until convergence or the maximum number of iterations is reached.
    
"""
function cover(sub_covers::AbstractVector{SubCover{INT}}, dns::Vector{TF}, solver::IPSolver; verbose::Bool = false) where{INT, TF}
    max_itr = solver.max_itr
    cx, n = γ0(sub_covers, dns)
    verbose && (@info "γ0 = $cx")
    scs_new = copy(sub_covers)
    cx_old = cx
    for i = 1:max_itr
        xs = IP_setcover(cx, scs_new, n, dns, verbose)
        cx = complexity(dns[xs .≈ 1.0])
        picked = pick(xs, sub_covers)
        verbose && (@info "IP Solver, Iteration $i, complexity = $cx")
        if (i == max_itr) || (cx ≈ cx_old)
            return picked, cx
        else
            cx_old = cx
        end
    end
end

function IP_setcover(γp::TF, sub_covers::AbstractVector{SubCover{INT}}, n::Int, dns::Vector{T}, verbose::Bool) where{INT, TF, T}
    fixeds = dns
    γs = 1 ./ γp .^ fixeds
    nsc = length(sub_covers)

    sets_id = [Vector{Int}() for _=1:n]
    for i in 1:nsc
        for j in sub_covers[i].ids
            push!(sets_id[j], i)
        end
    end

    # IP by JuMP
    model = Model(SCIP.Optimizer)
    !verbose && set_attribute(model, "display/verblevel", 0)
    set_attribute(model, "limits/gap", 0.05)

    @variable(model, 0 <= x[i = 1:nsc] <= 1, Int)
    @objective(model, Min, sum(x[i] * γs[i] for i in 1:nsc))
    for i in 1:n
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    optimize!(model)
    @assert is_solved_and_feasible(model)

    selected = [value(x[i]) for i in 1:nsc]

    return selected
end
