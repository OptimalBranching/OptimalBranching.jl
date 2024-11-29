struct BranchingRule{P, R}
    branches::Vector{Branch{P, R}}
end

"""
    optimal_branching_rule(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}

Generate optimal branches from a given branching table.

### Arguments
- `tbl::BranchingTable{INT}`: The branching table containing subcovers.
- `variables::Vector{T}`: A vector of variables to be used in the branching.
- `problem::P`: The problem instance being solved.
- `measure::M`: The measure used for evaluating the branches.
- `solver::S`: The solver used for the set cover problem.
- `::Type{R}`: The type of the result expected.
- `verbose::Bool`: Optional; if true, enables verbose output (default is false).

### Returns
A vector of `Branch` objects representing the optimal branches derived from the subcovers.
"""
function optimal_branching_rule(tbl::BranchingTable{INT}, variables::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}
    sub_covers = subcovers(tbl)
    Δρ = branching_vector(problem, sub_covers, measure, variables)
    cov, cx = minimize_γ(length(tbl.table), sub_covers, Δρ, solver)
    return BranchingRule([Branch(sub_cover.clause, variables, problem, R) for sub_cover in cov])
end

# TODO: use a data structure for the result, and define show instead.
# Q: why optimal? do not propagate contexts into all functions
function viz_optimal_branching(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; label = nothing) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}

    @assert (isnothing(label) || ((label isa AbstractVector) && (length(label) == length(vs))))

    sub_covers = subcovers(tbl)
    cov, cx = cover(sub_covers, problem, measure, vs, solver)

    label_string = (isnothing(label)) ? vs : label

    println("--------------------------------")
    println("complexity: $cx")
    println("branches:")
    for cov_i in cov
        println(clause_string(cov_i.clause, label_string))
    end
    println("branching vector: [$(join([dn(problem, measure, sc, vs) for sc in cov], ", "))]")
    println("--------------------------------")

    return cov, cx
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
    Branch the given problem using the specified solver configuration.

    # Arguments
    - `p::P`: The problem instance to branch.
    - `config::SolverConfig`: The configuration for the solver.

    # Returns
    The maximum result obtained from the branches.
"""
function reduce_and_branch(p::AbstractProblem, config::SolverConfig)
    (p isa NoProblem) && return zero(config.result_type)

    # TODO: why not just reduce directly?
    reduced_branches = reduce_problem(p, config.reducer, config.result_type)
    rule = if isnothing(reduced_branches)  # use the automatically generated branching rule
        strategy = config.branching_strategy
        variables = select(p, strategy.measure, strategy.selector)  # select a subset of variables
        tbl = branching_table(p, strategy.table_solver, variables)      # compute the BranchingTable
        pruned_tbl = prune(tbl, strategy.pruner, strategy.measure, p, variables)
        optimal_branching_rule(pruned_tbl, variables, p, strategy.measure, strategy.set_cover_solver, config.result_type)
    else
        BranchingRule(reduced_branches)
    end
    return maximum([(reduce_and_branch(b.problem, config) + b.result) for b in rule.branches])
end