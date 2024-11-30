"""
    optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, measure::AbstractMeasure, solver::AbstractSetCoverSolver)::DNF

Generate an optimal branching rule from a given branching table.

### Arguments
- `table`: A [`BranchingTable`](@ref) instance containing candidate clauses.
- `variables`: A vector of variables to perform the branching.
- `problem`: The problem instance being solved.
- `measure`: The measure used for evaluating the problem size reduction in the branches.
- `solver`: The solver used for the weighted minimum set cover problem, which can be either [`LPSolver`](@ref) or [`IPSolver`](@ref).

### Returns
A [`DNF`](@ref) object representing the optimal branching rule.
"""
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::AbstractSetCoverSolver)
    candidates = candidate_clauses(table)
    size_reductions = [measure(problem, m) - measure(first(apply_branch(problem, candidate.clause, variables)), m) for candidate in candidates]
    selection, _ = minimize_γ(length(table.table), candidates, size_reductions, solver; γ0=2.0)
    return DNF(map(i->candidates[i].clause, selection))
end

# TODO: we need to extend this function to trim the candidate clauses
"""
    candidate_clauses(tbl::BranchingTable{INT}) where {INT}

Generates candidate clauses from a branching table.

### Arguments
- `tbl::BranchingTable{INT}`: The branching table containing bit strings.

### Returns
- `Vector{CandidateClause{INT}}`: A vector of `CandidateClause` objects generated from the branching table.
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

    allcovers = [CandidateClause(covered_items(bss, c), c) for c in all_clauses]
    return allcovers
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

"""
    BranchingStrategy
    BranchingStrategy(; kwargs...)

A struct representing the configuration for a solver, including the reducer and branching strategy.

### Fields
- `table_solver::AbstractTableSolver`: The solver to resolve the relevant bit strings and generate a branching table.
- `set_cover_solver::AbstractSetCoverSolver = IPSolver()`: The solver to solve the set covering problem.
- `selector::AbstractSelector`: The selector to select the next branching variable or decision.
- `m::AbstractMeasure`: The measure to evaluate the performance of the branching strategy.
"""
@kwdef struct BranchingStrategy{TS<:AbstractTableSolver, SCS<:AbstractSetCoverSolver, SL<:AbstractSelector, M<:AbstractMeasure}
    set_cover_solver::SCS = IPSolver()
    table_solver::TS
    selector::SL
    measure::M
end
Base.show(io::IO, config::BranchingStrategy) = print(io, 
"""
BranchingStrategy
├── table_solver - $(config.table_solver)
├── set_cover_solver - $(config.set_cover_solver)
├── selector - $(config.selector)
└── measure - $(config.measure)
""")

"""
    reduce_and_branch(problem::AbstractProblem, config::BranchingStrategy; reducer::AbstractReducer=NoReducer(), result_type=Int)

Branch the given problem using the specified solver configuration.

### Arguments
- `problem`: The problem instance to solve.
- `config`: The configuration for the solver, which is a [`BranchingStrategy`](@ref) instance.

### Keyword Arguments
- `reducer::AbstractReducer=NoReducer()`: The reducer to reduce the problem size.
- `result_type::Type{TR}`: The type of the result that the solver will produce.

### Returns
The resulting value, which may have different type depending on the `result_type`.
"""
function reduce_and_branch(problem::AbstractProblem, config::BranchingStrategy; reducer::AbstractReducer=NoReducer(), result_type=Int)
    isempty(problem) && return zero(result_type)
    # reduce the problem
    rp, reducedvalue = reduce_problem(result_type, problem, reducer)
    rp !== problem && return reduce_and_branch(rp, config) + reducedvalue

    # branch the problem
    variables = select_variables(rp, config.measure, config.selector)  # select a subset of variables
    tbl = branching_table(rp, config.table_solver, variables)      # compute the BranchingTable
    rule = optimal_branching_rule(tbl, variables, rp, config.measure, config.set_cover_solver)  # compute the optimal branching rule
    return maximum(rule.clauses) do branch  # branch and recurse
        subproblem, localvalue = apply_branch(rp, branch, variables)
        reduce_and_branch(subproblem, config) + localvalue + reducedvalue
    end
end