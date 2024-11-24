"""
    Generate optimal branches from a given branching table.

    # Arguments
    - `tbl::BranchingTable{INT}`: The branching table containing subcovers.
    - `vs::Vector{T}`: A vector of variables to be used in the branching.
    - `problem::P`: The problem instance being solved.
    - `measure::M`: The measure used for evaluating the branches.
    - `solver::S`: The solver used for the set cover problem.
    - `::Type{R}`: The type of the result expected.
    - `verbose::Bool`: Optional; if true, enables verbose output (default is false).

    # Returns
    A vector of `Branch` objects representing the optimal branches derived from the subcovers.
"""
function optimal_branching(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}
    sub_covers = subcovers(tbl)
    cov, cx = cover(sub_covers, problem, measure, vs, solver; verbose)
    branches = [Branch(sub_cover.clause, vs, problem, R) for sub_cover in cov]
    return branches
end


"""
    Branch the given problem using the specified solver configuration.

    # Arguments
    - `p::P`: The problem instance to branch.
    - `config::SolverConfig`: The configuration for the solver.

    # Returns
    The maximum result obtained from the branches.
"""
function branch(p::P, config::SolverConfig) where{P<:AbstractProblem}

    (p isa NoProblem) && return zero(config.result_type)

    reduced = problem_reduce(p, config.reducer, config.result_type)
    branches = !isnothing(reduced) ? [Branch(reduced[1], reduced[2])] : solve_branches(p, config.branching_strategy, config.result_type)

    return maximum([(branch(b.problem, config) + b.result) for b in branches])
end

"""
    Solve branches of the given problem using the specified branching strategy.

    # Arguments
    - `p::P`: The problem instance to solve branches for.
    - `strategy::OptBranchingStrategy`: The strategy to use for branching.
    - `result_type::Type{R}`: The type of the result expected.

    # Returns
    A vector of branches derived from the problem using the specified strategy.
"""
function solve_branches(p::P, strategy::OptBranchingStrategy, result_type::Type{R}) where{P<:AbstractProblem, R<:AbstractResult}

    vs = select(p, strategy.measure, strategy.selector)
    tbl = solve_table(p, strategy.table_solver, vs)
    pruned_tbl = prune(tbl, strategy.pruner, strategy.measure, p, vs)
    branches = optimal_branching(pruned_tbl, vs, p, strategy.measure, strategy.set_cover_solver, result_type)

    return branches
end
