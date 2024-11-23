function optimal_branching(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}
    sub_covers = subcovers(tbl)
    cov, cx = cover(sub_covers, problem, measure, vs, solver; verbose)
    branches = Branches([Branch(sub_cover.clause, vs, problem, R) for sub_cover in cov])
    return branches
end


function solve(p::P, config::SolverConfig) where{P<:AbstractProblem}
    reduce!(p, config.reducer)
    branches = solve_branches(p, config.branching_strategy)
    return sum([(b.problem isa NoProblem) ? b.result : (solve(b.problem, config) * b.result) for b in branches])
end

function solve_branches(p::P, strategy::OptimalBranching) where{P<:AbstractProblem}
    vs = select(p, strategy.measure, strategy.selector)
    tbl = solve_table(p, strategy.table_solver, vs)
    pruned_tbl = prune(tbl, strategy.pruner, strategy.measure, p, vs)
    branches = optimal_branching(pruned_tbl, vs, p, strategy.measure, strategy.set_cover_solver, strategy.table_result)
    return branches
end
