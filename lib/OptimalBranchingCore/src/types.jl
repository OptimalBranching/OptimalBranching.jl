"""
    AbstractProblem

An abstract type representing a generic problem in the optimal branching framework. 
This serves as a base type for all specific problem types that will be implemented.
"""
abstract type AbstractProblem end

"""
    AbstractResult

An abstract type representing a generic result in the optimal branching framework. 
This serves as a base type for all specific result types that will be implemented.
"""
abstract type AbstractResult end

"""
    NoResult

A concrete implementation of AbstractResult representing the absence of a result. 
This is used as a placeholder in scenarios where no valid result is present.

# Fields
None

"""
struct NoResult <: AbstractResult end

"""
    apply_branch(problem::AbstractProblem, ::Clause, vs)

Applies a clause to a NoProblem instance, returning a NoProblem instance. 
This function serves as a placeholder for scenarios where no valid problem is present.

# Arguments
- `::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::Clause`: A clause that is being applied (not used in this context).
- `vs`: A vector of variables (not used in this context).

# Returns
- `NoProblem()`: An instance of NoProblem, indicating that no problem exists.

"""
function apply_branch end

"""
    result(problem, ::Clause, vs, ::Type{R}) where{R<:AbstractResult}

Generates a result from a NoProblem instance when a clause is applied. 
This function serves as a placeholder for scenarios where no valid result is present.

# Arguments
- `::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::Clause`: A clause that is being applied (not used in this context).
- `vs`: A vector of variables (not used in this context).
- `::Type{R}`: The type of result expected, which must be a subtype of AbstractResult.

# Returns
- `NoResult()`: An instance of NoResult, indicating that no valid result exists.

"""
function result end

"""
    AbstractMeasure

An abstract type representing a measure in the context of branching problems. 
This serves as a base type for all specific measure implementations.
"""
abstract type AbstractMeasure end

"""
    measure(::NoProblem, ::AbstractMeasure)

Calculates a measure for a NoProblem instance. 
This function serves as a placeholder for scenarios where no valid problem is present.

# Arguments
- `::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::AbstractMeasure`: An abstract measure type, which is not utilized in this context.

# Returns
- `Int`: The measure value, which is always `0` for a NoProblem instance.
"""
function measure end

"""
    AbstractReducer

An abstract type representing a reducer in the context of branching problems. 
This serves as a base type for all specific reducer implementations.
"""
abstract type AbstractReducer end

"""
    reduce_problem(p::NoProblem, ::AbstractReducer, ::Type{R}) where{R<:AbstractResult}

Reduces a problem represented by a NoProblem instance. 
This function serves as a placeholder for scenarios where no valid problem is present.

# Arguments
- `p::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::AbstractReducer`: An abstract reducer type, which is not utilized in this context.
- `::Type{R}`: The type of result expected, which must be a subtype of AbstractResult.

# Returns
- `NoProblem()`: An instance of NoProblem, indicating that no problem exists.
"""
function reduce_problem end

"""
    AbstractSelector

An abstract type representing a selector in the context of branching problems. 
This serves as a base type for all specific selector implementations.
"""
abstract type AbstractSelector end

"""
    select(::NoProblem, ::AbstractMeasure, ::NoSelector)

Selects a branching strategy for a NoProblem instance. 
This function serves as a placeholder for scenarios where no valid selection is present.

# Arguments
- `::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::AbstractMeasure`: An abstract measure type, which is not utilized in this context.
- `::NoSelector`: An instance of NoSelector, representing the absence of a selector.

# Returns
- `nothing`: Indicates that no selection is made due to the absence of a problem.
"""
function select end

"""
    AbstractPruner

An abstract type representing a pruner in the context of branching problems. 
This serves as a base type for all specific pruner implementations.

"""
abstract type AbstractPruner end

"""
    NoPruner

A struct representing a no-operation pruner. 
This pruner does not modify the branching table during the pruning process.

"""
struct NoPruner <: AbstractPruner end

"""
    prune(bt::BranchingTable, ::NoPruner, ::M, ::P, vs)

Applies a no-operation pruning strategy to the given branching table. 
This function serves as a placeholder for scenarios where no pruning is required.

# Arguments
- `bt::BranchingTable`: The branching table to be pruned.
- `::NoPruner`: An instance of NoPruner, indicating that no pruning will occur.
- `::M`: An abstract measure type, which is not utilized in this context.
- `::P`: An abstract problem type, which is not utilized in this context.
- `vs`: A vector of values associated with the branching process.

# Returns
- `bt`: The original branching table, unchanged.
"""
prune(bt::BranchingTable, ::NoPruner, ::M, ::P, vs) where{M<:AbstractMeasure, P<:AbstractProblem} = bt

"""
    AbstractTableSolver

An abstract type representing a solver for table-based problems. 
This serves as a base type for all specific table solver implementations.
"""
abstract type AbstractTableSolver end

"""
    branching_table

Solves a given problem using a specified table solver.

# Arguments
- `::NoProblem`: An instance of NoProblem, representing the absence of a problem.
- `::AbstractTableSolver`: An abstract table solver type, which is not utilized in this context.
- `vs`: A vector of values associated with the problem-solving process.

# Returns
- `nothing`: Indicates that no solution is produced due to the absence of a problem.
"""
function branching_table end

"""
    AbstractSetCoverSolver

An abstract type representing a solver for set covering problems. 
This serves as a base type for all specific set cover solver implementations.

"""
abstract type AbstractSetCoverSolver end

"""
    LPSolver

A struct representing a linear programming solver for set covering problems.

# Fields
- `max_itr::Int`: The maximum number of iterations allowed for the solver.

# Constructors
- `LPSolver(max_itr::Int)`: Creates a new instance of LPSolver with a specified maximum number of iterations.
- `LPSolver()`: Creates a new instance of LPSolver with a default maximum of 10 iterations.

"""
Base.@kwdef struct LPSolver <: AbstractSetCoverSolver 
    max_itr::Int = 5
    verbose::Bool = false
end

"""
    IPSolver

A struct representing an integer programming solver for set covering problems.

# Fields
- `max_itr::Int`: The maximum number of iterations allowed for the solver.

# Constructors
- `IPSolver(max_itr::Int)`: Creates a new instance of IPSolver with a specified maximum number of iterations.
- `IPSolver()`: Creates a new instance of IPSolver with a default maximum of 10 iterations.

"""
Base.@kwdef struct IPSolver <: AbstractSetCoverSolver 
    max_itr::Int = 5
    verbose::Bool = false
end

"""
    AbstractBranchingStrategy

An abstract type representing a branching strategy in the optimization process.

"""
abstract type AbstractBranchingStrategy end

# AutoBranchingStrategy? because sometimes it is not optimal, e.g. when using LP
"""
    OptBranchingStrategy

A struct representing an optimal branching strategy that utilizes various components for solving optimization problems.

# Fields
- `table_solver::TS`: An instance of a table solver, which is responsible for solving the underlying table representation of the problem.
- `set_cover_solver::SCS`: An instance of a set cover solver, which is used to solve the set covering problem.
- `pruner::PR`: An instance of a pruner, which is used to eliminate unnecessary branches in the search space.
- `selector::SL`: An instance of a selector, which is responsible for selecting the next branching variable or decision.
- `measure::M`: An instance of a measure, which is used to evaluate the performance of the branching strategy.

"""
struct OptBranchingStrategy{TS<:AbstractTableSolver, SCS<:AbstractSetCoverSolver, PR<:AbstractPruner, SL<:AbstractSelector, M<:AbstractMeasure} <: AbstractBranchingStrategy 
    table_solver::TS
    set_cover_solver::SCS
    pruner::PR
    selector::SL
    measure::M
end
Base.show(io::IO, strategy::OptBranchingStrategy) = print(io, 
"""
OptBranchingStrategy
    ├── table_solver - $(strategy.table_solver)
    ├── set_cover_solver - $(strategy.set_cover_solver)
    ├── pruner - $(strategy.pruner)
    ├── selector - $(strategy.selector)
    └── measure - $(strategy.measure)
""")

"""
    SolverConfig

A struct representing the configuration for a solver, including the reducer and branching strategy.

# Fields
- `reducer::R`: An instance of a reducer, which is responsible for reducing the problem size.
- `branching_strategy::B`: An instance of a branching strategy, which guides the search process.
- `result_type::Type{TR}`: The type of the result that the solver will produce.

"""
struct SolverConfig{R<:AbstractReducer, B<:AbstractBranchingStrategy, TR<:AbstractResult}
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