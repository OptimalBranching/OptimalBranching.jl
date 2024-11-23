function complexity(sbranches::Vector{T}) where{T}
    # solve x, where 1 = sum(x^(-i) for i in sbranches)
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

function dn(p::P, m::M, subcover::SubCover{INT}, vs::Vector{T}) where{P<:AbstractProblem, M<:AbstractMeasure, INT<:Integer, T}
    return measure(p, m) - measure(apply(p, subcover.clause, vs), m)
end

function cover(sub_covers::AbstractVector{SubCover{INT}}, p::P, m::M, vs::Vector{T}, solver::LPSolver; verbose::Bool = false) where{INT, P<:AbstractProblem, M<:AbstractMeasure, T}
    dns = [dn(p, m, subcover, vs) for subcover in sub_covers]
    max_itr = solver.max_itr
    n = max_id(sub_covers)
    cx = complexity(dns)
    verbose && (@info "γ0 = $(cx)")
    scs_new = copy(sub_covers)
    cx_old = cx
    for i =1:max_itr
        xs = LP_setcover(cx, scs_new, n, dns, verbose)
        picked = random_pick(xs, sub_covers, n)
        cx = complexity(picked)
        verbose && (@info "LP Solver, Iteration $i, complexity = $cx")
        if (i == max_itr)  || (cx ≈ cx_old)
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

    return [sub_covers[i] for i in picked]
end

function pick(xs::Vector{TF}, sub_covers::AbstractVector{SubCover{INT}}) where{INT, TF}
    return [sub_covers[i] for i in 1:length(xs) if xs[i] ≈ 1.0]
end

function cover(sub_covers::AbstractVector{SubCover{INT}}, p::P, m::M, vs::Vector{T}, solver::IPSolver; verbose::Bool = false) where{INT, P<:AbstractProblem, M<:AbstractMeasure, T}
    dns = [dn(p, m, subcover, vs) for subcover in sub_covers]
    max_itr = solver.max_itr
    n = max_id(sub_covers)
    cx = complexity(dns)
    verbose && (@info "γ0 = $cx")
    scs_new = copy(sub_covers)
    cx_old = cx
    for i =1:max_itr
        xs = IP_setcover(cx, scs_new, n, dns, verbose)
        picked = pick(xs, sub_covers)
        cx = complexity(picked)
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
