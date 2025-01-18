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
    return minimize_γ(table, candidates, size_reductions, solver; γ0 = 2.0)
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
    branch_and_reduce(problem::AbstractProblem, config::BranchingStrategy; reducer=NoReducer(), show_progress=false)

Branch the given problem using the specified solver configuration.

### Arguments
- `problem`: The problem instance to solve.
- `config`: The configuration for the solver, which is a [`BranchingStrategy`](@ref) instance.
- `reducer=NoReducer()`: The reducer to reduce the problem size.

### Keyword Arguments
- `show_progress=false`: Whether to show the progress of the branching.

### Returns
A [`SolutionAndCount`](@ref) object representing the solution and the number of branches.
"""
function branch_and_reduce(problem::AbstractProblem, config::BranchingStrategy, reducer::AbstractReducer=NoReducer(); show_progress=false)
    INT = BitBasis.longinttype(num_variables(problem), 2)
    return branch_and_reduce(INT, problem, config, reducer, show_progress, Tuple{Int,Int}[])
end
function branch_and_reduce(::Type{INT}, problem::AbstractProblem, config::BranchingStrategy, reducer::AbstractReducer, show_progress::Bool, tag::Vector{Tuple{Int, Int}}) where INT
    @debug "Branching and reducing problem" problem
    iszero(num_variables(problem)) && return SolutionAndCount(0.0, zero(INT), 1)
    # reduce the problem
    rp, info = reduce_problem(INT, problem, reducer)
    if info.reduced
        res = branch_and_reduce(INT, rp, config, reducer, show_progress, tag)
        solution = map_config_back(res.solution, info)
        return SolutionAndCount(res.size + info.solution_size_gain, solution, res.count)
    end

    # branch the problem
    variables = select_variables(rp, config.measure, config.selector)  # select a subset of variables
    tbl = branching_table(rp, config.table_solver, variables)      # compute the BranchingTable
    result = optimal_branching_rule(tbl, variables, rp, config.measure, config.set_cover_solver)  # compute the optimal branching rule
    return mapreduce(compare_solutions, enumerate(get_clauses(result))) do (i, branch)  # branch and recurse
        show_progress && (print_sequence(stdout, tag); println(stdout))
        subproblem, sub_variables, localsolution = apply_branch(rp, branch, variables)
        sub_solution = branch_and_reduce(INT, subproblem, config, reducer, show_progress,
                (show_progress ? [tag..., (i, length(get_clauses(result)))] : tag))  # for tagging a branch
        res = join_solutions(promote_local_solution(INT, sub_solution, sub_variables), promote_local_solution(INT, localsolution, variables))
        return res
    end
end

function promote_local_solution(::Type{INT}, loc::SolutionAndCount, variables) where INT
    return SolutionAndCount(loc.size, map_solution(INT, loc.solution, 1:length(variables), variables), loc.count)
end

function print_sequence(io::IO, sequence::Vector{Tuple{Int,Int}})
    for (i, n) in sequence
        if i == n
            print(io, "■")
        elseif i == 1
            print(io, "□")
        else
            print(io, "▦")
        end
    end
end