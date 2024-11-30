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
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, measure::AbstractMeasure, solver::AbstractSetCoverSolver)
    candidates = candidate_clauses(table)
    Δρ = branching_vector(problem, variables, candidates, measure)
    selection, _ = minimize_γ(length(table.table), candidates, Δρ, solver)
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

"""
    BranchingStrategy

A struct representing an optimal branching strategy that utilizes various components for solving optimization problems.

# Fields
- `table_solver::TS`: An instance of a table solver, which is responsible for solving the underlying table representation of the problem.
- `set_cover_solver::SCS`: An instance of a set cover solver, which is used to solve the set covering problem.
- `selector::SL`: An instance of a selector, which is responsible for selecting the next branching variable or decision.
- `measure::M`: An instance of a measure, which is used to evaluate the performance of the branching strategy.

"""
struct BranchingStrategy{TS<:AbstractTableSolver, SCS<:AbstractSetCoverSolver, SL<:AbstractSelector, M<:AbstractMeasure}
    table_solver::TS
    set_cover_solver::SCS
    selector::SL
    measure::M
end
Base.show(io::IO, strategy::BranchingStrategy) = print(io, 
"""
BranchingStrategy
    ├── table_solver - $(strategy.table_solver)
    ├── set_cover_solver - $(strategy.set_cover_solver)
    ├── selector - $(strategy.selector)
    └── measure - $(strategy.measure)
""")

"""
    SolverConfig

A struct representing the configuration for a solver, including the reducer and branching strategy.

# Fields
- `reducer::R`: An instance of a reducer, which is responsible for reducing the problem size.
- `branching_strategy::BranchingStrategy`: An instance of a branching strategy, which guides the search process.
- `result_type::Type{TR}`: The type of the result that the solver will produce.

"""
struct SolverConfig{R<:AbstractReducer, B<:BranchingStrategy, TR}
    reducer::R
    branching_strategy::B
    result_type::Type{TR}
end
Base.show(io::IO, config::SolverConfig) = print(io, 
"""
SolverConfig
├── reducer - $(config.reducer) 
├── result_type - $(config.result_type)
└── branching_strategy - $(config.branching_strategy) 
""")

"""
    Branch the given problem using the specified solver configuration.

    # Arguments
    - `p::P`: The problem instance to branch.
    - `config::SolverConfig`: The configuration for the solver.

    # Returns
    The maximum result obtained from the branches.
"""
function reduce_and_branch(p::AbstractProblem, config::SolverConfig)
    rp, reducedvalue = reduce_problem(config.result_type, p, config.reducer)
    isempty(rp) && return reducedvalue

    strategy = config.branching_strategy
    variables = select_variables(rp, strategy.measure, strategy.selector)  # select a subset of variables
    tbl = branching_table(rp, strategy.table_solver, variables)      # compute the BranchingTable
    rule = optimal_branching_rule(tbl, variables, rp, strategy.measure, strategy.set_cover_solver)
    return maximum(rule.clauses) do branch
        subproblem, localvalue = apply_branch(rp, branch, variables)
        reduce_and_branch(subproblem, config) + localvalue + reducedvalue
    end
end