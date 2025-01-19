"""
    optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, measure::AbstractMeasure, solver::AbstractSetCoverSolver)::OptimalBranchingResult

Generate an optimal branching rule from a given branching table.

### Arguments
- `table`: A [`BranchingTable`](@ref) instance containing candidate clauses.
- `variables`: A vector of variables to perform the branching.
- `problem`: The problem instance being solved.
- `measure`: The measure used for evaluating the problem size reduction in the branches.
- `solver`: The solver used for the weighted minimum set cover problem, which can be either [`LPSolver`](@ref) or [`IPSolver`](@ref).

### Returns
A [`OptimalBranchingResult`](@ref) object representing the optimal branching rule.
"""
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::AbstractSetCoverSolver)
    candidates = candidate_clauses(table)
    size_reductions = [size_reduction(problem, m, candidate, variables) for candidate in candidates]
    return minimize_γ(table, candidates, size_reductions, solver)
end

function size_reduction(p::AbstractProblem, m::AbstractMeasure, cl::Clause{INT}, variables::Vector) where {INT}
    return measure(p, m) - measure(first(apply_branch(p, cl, variables)), m)
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
@kwdef struct BranchingStrategy{TS <: AbstractTableSolver, SCS <: AbstractSetCoverSolver, SL <: AbstractSelector, M <: AbstractMeasure}
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
    branch_and_reduce(problem::AbstractProblem, config::BranchingStrategy; reducer::AbstractReducer=NoReducer(), result_type=Int, show_progress=false)

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
function branch_and_reduce(problem::AbstractProblem, config::BranchingStrategy, reducer::AbstractReducer, result_type; show_progress=false, tag=Tuple{Int,Int}[])
    @debug "Branching and reducing problem" problem
    has_zero_size(problem) && return zero(result_type)
    # reduce the problem
    rp, reducedvalue = reduce_problem(result_type, problem, reducer)
    rp !== problem && return branch_and_reduce(rp, config, reducer, result_type; tag, show_progress) * reducedvalue

    # branch the problem
    variables = select_variables(rp, config.measure, config.selector)  # select a subset of variables
    tbl = branching_table(rp, config.table_solver, variables)      # compute the BranchingTable
    result = optimal_branching_rule(tbl, variables, rp, config.measure, config.set_cover_solver)  # compute the optimal branching rule
    return sum(enumerate(get_clauses(result))) do (i, branch)  # branch and recurse
        show_progress && (print_sequence(stdout, tag); println(stdout))
        subproblem, localvalue = apply_branch(rp, branch, variables)
        branch_and_reduce(subproblem, config, reducer, result_type;
                tag=(show_progress ? [tag..., (i, length(get_clauses(result)))] : tag),
                show_progress) * result_type(localvalue) * reducedvalue
    end
end

function print_sequence(io::IO, sequence::Vector{Tuple{Int,Int}})
    for (i, n) in sequence
        if i == n
            print(io, "■")
        elseif i == 1
            print(io, "⋅")
        else
            print(io, "□")
        end
    end
end