"""
    AbstractProblem

The problem type that can be used in the optimal branching framework.
"""
abstract type AbstractProblem end

"""
    apply_branch(problem::AbstractProblem, clause::Clause, vertices::Vector)::Tuple{AbstractProblem, Number}

Create a branch from the given clause applied to the specified vertices.

### Arguments
- `problem`: The problem instance.
- `clause`: The clause that containing the information about how to fix the values of the variables.
- `vertices`: A vector of vertices to be considered for the branch.

### Returns
A tuple of two values:
- `AbstractProblem`: A new instance of `AbstractProblem` with reduced size.
- `Number`: The local gain of the branch, which will be added to the global gain.
"""
function apply_branch end

"""
    AbstractMeasure

The base type for the measure of the problem size in terms of computational hardness.
Some widely used measures include the number of variables, the vertices with connectivity of at least 3, etc.
"""
abstract type AbstractMeasure end

"""
    measure(problem::AbstractProblem, measure::AbstractMeasure)::Number

Calculate the size of the problem, reducing which serves as the guiding principle for the branching strategy.

### Arguments
- `problem`: The problem instance.
- `measure`: The measure of the problem size.

### Returns
A real number representing the problem size.
"""
function measure end

"""
    AbstractReducer

An abstract type representing a reducer in the context of branching problems. 
This serves as a base type for all specific reducer implementations.
"""
abstract type AbstractReducer end
struct NoReducer <: AbstractReducer end

"""
    reduce_problem(::Type{R}, problem::AbstractProblem, reducer::AbstractReducer) where R

Reduces the problem size directly, e.g. by graph rewriting. It is a crucial step in the reduce and branch strategy.

### Arguments
- `R`: The element type used for computing the size of solution. The should have an additive commutative monoid structure.
- `problem`: The problem instance.
- `reducer`: The reducer.

### Returns
A tuple of two values:
- `AbstractProblem`: A new instance of `AbstractProblem` with reduced size.
- `Number`: The local gain of the reduction, which will be added to the global gain.
"""
reduce_problem(::Type{T}, problem::AbstractProblem, ::NoReducer) where T = (problem, zero(T))

"""
    AbstractSelector

An abstract type for the strategy of selecting a subset of variables to be branched.
"""
abstract type AbstractSelector end

# TODO: do we need this? the problem is the selection strategy can be numerous.
"""
    select_variables(problem::AbstractProblem, measure::AbstractMeasure, selector::AbstractSelector)::Vector{Int}

Selects a branching strategy for a `AbstractProblem` instance. 

### Arguments
- `problem`: The problem instance.
- `measure`: The measure of the problem size.
- `selector`: The variables selection strategy, which is a subtype of [`AbstractSelector`](@ref).

### Returns
A vector of indices of the selected variables.
"""
function select_variables end

"""
    AbstractTableSolver

An abstract type for the strategy of obtaining the branching table.
"""
abstract type AbstractTableSolver end

"""
    branching_table(problem::AbstractProblem, table_solver::AbstractTableSolver, variables::Vector{Int})

Obtains the branching table for a given problem using a specified table solver.

### Arguments
- `problem`: The problem instance.
- `table_solver`: The table solver, which is a subtype of [`AbstractTableSolver`](@ref).
- `variables`: A vector of indices of the variables to be considered for the branching table.

### Returns
A branching table, which is a subtype of [`AbstractBranchingTable`](@ref).
"""
function branching_table end