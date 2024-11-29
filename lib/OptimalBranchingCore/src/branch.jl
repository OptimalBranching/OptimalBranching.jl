"""
    struct Branch

A struct representing a branching strategy.

# Fields
- `vertices_removed::Vector{Int}`: A vector of integers representing the vertices removed in the branching strategy.
- `mis::Int`: An integer representing the maximum independent set (MIS) size of the branching strategy.

"""
struct Branch{P<:AbstractProblem, R}
    problem::P
    result::R
end

function Branch(clause::Clause{INT}, vs::Vector{T}, p::P, ::Type{R}) where {INT, T, P<:AbstractProblem, R<:AbstractResult}
    return Branch(apply_branch(p, clause, vs), result(p, clause, vs, R))
end

struct BranchingRule{P, R}
    branches::Vector{Branch{P, R}}
end

"""
    optimal_branching_rule(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; verbose::Bool = false) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}

Generate optimal branches from a given branching table.

### Arguments
- `tbl::BranchingTable{INT}`: The branching table containing candidate clauses.
- `variables::Vector{T}`: A vector of variables to be used in the branching.
- `problem::P`: The problem instance being solved.
- `measure::M`: The measure used for evaluating the branches.
- `solver::S`: The solver used for the set cover problem.
- `::Type{R}`: The type of the result expected.
- `verbose::Bool`: Optional; if true, enables verbose output (default is false).

### Returns
A vector of `Branch` objects representing the optimal branches derived from the candidate clauses.
"""
function optimal_branching_rule(tbl::BranchingTable{INT}, variables::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}
    clauses = candidate_clauses(tbl)
    Δρ = branching_vector(problem, variables, clauses, measure)
    cov, cx = minimize_γ(length(tbl.table), clauses, Δρ, solver)
    return BranchingRule([Branch(sub_cover.clause, variables, problem, R) for sub_cover in cov])
end


"""
    candidate_clauses(tbl::BranchingTable{INT}) where {INT}

Generates candidate_clauses from a branching table.

# Arguments
- `tbl::BranchingTable{INT}`: The branching table containing bit strings.

# Returns
- `Vector{SubCover{INT}}`: A vector of `SubCover` objects generated from the branching table.

# Description
This function calls the `candidate_clauses` function with the bit length and table from the provided branching table to generate the corresponding candidate_clauses.
"""
function candidate_clauses(tbl::BranchingTable{INT}) where {INT}
    n, bss = tbl.bit_length, tbl.table
    bs = vcat(bss...)
    all_clauses = Set{Clause{INT}}()
    temp_clauses = [Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)]
    while !isempty(temp_clauses)
        c = pop!(temp_clauses)
        if !(c in all_clauses)
            push!(all_clauses, c)
            idc = Set(covered_items(bss, c))
            for i in 1:length(bss)
                if i ∉ idc                
                    for b in bss[i]
                        c_new = gather2(n, c, Clause(bmask(INT, 1:n), b))
                        if (c_new != c) && c_new.mask != 0
                            push!(temp_clauses, c_new)
                        end
                    end
                end
            end
        end
    end

    allcovers = [SubCover(covered_items(bss, c), c) for c in all_clauses]
    return allcovers
end

# TODO: use a data structure for the result, and define show instead.
# Q: why optimal? do not propagate contexts into all functions
function viz_optimal_branching(tbl::BranchingTable{INT}, vs::Vector{T}, problem::P, measure::M, solver::S, ::Type{R}; label = nothing) where{INT, T, P<:AbstractProblem, M<:AbstractMeasure, S<:AbstractSetCoverSolver, R<:AbstractResult}

    @assert (isnothing(label) || ((label isa AbstractVector) && (length(label) == length(vs))))

    clauses = candidate_clauses(tbl)
    cov, cx = cover(clauses, problem, measure, vs, solver)

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
    isempty(p) && return zero(config.result_type)
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