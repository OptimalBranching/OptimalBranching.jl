function optimal_branching(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}
    sub_covers = subcovers(tbl)
    cov, cx = cover(sub_covers, problem, measure, vs, solver; verbose)
    branches = [Branch(sub_cover.clause, vs, problem, R) for sub_cover in cov]
    return branches
end


function branch(p::P, config::SolverConfig) where{P<:AbstractProblem}

    (p isa NoProblem) && return zero(config.result_type)

    reduced = reduce(p, config.reducer, config.result_type)
    branches = !isnothing(reduced) ? [Branch(reduced[1], reduced[2])] : solve_branches(p, config.branching_strategy, config.result_type)

    return maximum([(branch(b.problem, config) + b.result) for b in branches])
end

function solve_branches(p::P, strategy::OptimalBranching, result_type::Type{R}) where{P<:AbstractProblem, R<:AbstractResult}

    vs = select(p, strategy.measure, strategy.selector)
    tbl = solve_table(p, strategy.table_solver, vs)
    pruned_tbl = prune(tbl, strategy.pruner, strategy.measure, p, vs)
    branches = optimal_branching(pruned_tbl, vs, p, strategy.measure, strategy.set_cover_solver, result_type)

    return branches
end
