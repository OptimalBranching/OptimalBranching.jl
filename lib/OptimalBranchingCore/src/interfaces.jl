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

# TODO: do we really need it?
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

# can not understand.
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