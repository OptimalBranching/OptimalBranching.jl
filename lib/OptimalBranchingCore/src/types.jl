abstract type AbstractProblem end
struct NoProblem <: AbstractProblem end
abstract type AbstractResult end
struct NoResult <: AbstractResult end

apply(::NoProblem, ::Clause, vs) = NoProblem()
result(::NoProblem, ::Clause, vs, ::Type{R}) where{R<:AbstractResult} = NoResult()

# abstract type AbstractBranching end

abstract type AbstractMeasure end
struct NoMeasure <: AbstractMeasure end
function measure(::P, ::NoMeasure) where{P<:AbstractProblem} return 0 end

abstract type AbstractReducer end
struct NoReducer <: AbstractReducer end
function reduce(p::P, ::NoReducer, ::Type{R}) where{P<:AbstractProblem, R<:AbstractResult} return nothing end

abstract type AbstractSelector end
struct NoSelector <: AbstractSelector end
function select(::P, ::M, ::NoSelector) where{P<:AbstractProblem, M<:AbstractMeasure} return nothing end

abstract type AbstractPruner end
struct NoPruner <: AbstractPruner end
prune(bt::BranchingTable, ::NoPruner, ::M, ::P, vs) where{M<:AbstractMeasure, P<:AbstractProblem} = bt

abstract type AbstractTableSolver end
struct NoTableSolver <: AbstractTableSolver end
solve_table(::P, ::NoTableSolver, vs) where{P<:AbstractProblem} = nothing

abstract type AbstractSetCoverSolver end
struct LPSolver <: AbstractSetCoverSolver max_itr::Int end
struct IPSolver <: AbstractSetCoverSolver max_itr::Int end

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
    return Branch(apply(p, clause, vs), result(p, clause, vs, R))
end


abstract type AbstractBranchingStrategy end
struct NoBranchingStrategy <: AbstractBranchingStrategy end
struct OptimalBranching{TS<:AbstractTableSolver, SCS<:AbstractSetCoverSolver, PR<:AbstractPruner, SL<:AbstractSelector, M<:AbstractMeasure} <: AbstractBranchingStrategy 
    table_solver::TS
    set_cover_solver::SCS
    pruner::PR
    selector::SL
    measure::M
end

struct SolverConfig{R<:AbstractReducer, B<:AbstractBranchingStrategy, TR<:AbstractResult}
    reducer::R
    branching_strategy::B
    result_type::Type{TR}
end
