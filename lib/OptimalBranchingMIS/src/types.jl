"""
    mutable struct MISProblem{INT <: Integer, VT<:AbstractVector} <: AbstractProblem

Represents a Maximum (Weighted) Independent Set (M(W)IS) problem.

# Fields
- `g::SimpleGraph`: The graph associated with the M(W)IS problem.
- `weights::VT`: The weights of the vertices in the graph. It's set to be UnitWeight if the graph is not weighted.

# Methods
- `copy(p::MISProblem)`: Creates a copy of the given `MISProblem`.
- `Base.show(io::IO, p::MISProblem)`: Displays the number of vertices in the `MISProblem`.
"""
mutable struct MISProblem{INT <: Integer, VT<:AbstractVector} <: AbstractProblem
    g::SimpleGraph{Int}
    weights::VT
    function MISProblem(g::SimpleGraph{Int}, weights::VT) where VT
        new{BitBasis.longinttype(nv(g), 2), VT}(g, weights)
    end
    function MISProblem(g::SimpleGraph{Int})
        new{BitBasis.longinttype(nv(g), 2), UnitWeight}(g, UnitWeight(nv(g)))
    end
end
Base.copy(p::MISProblem) = MISProblem(copy(p.g), copy(p.weights))
Base.show(io::IO, p::MISProblem) = print(io, "MISProblem($(nv(p.g)))")
OptimalBranchingCore.has_zero_size(p::MISProblem) = nv(p.g) == 0
Base.:(==)(p1::MISProblem{T1}, p2::MISProblem{T2}) where {T1, T2} = 
    (T1 == T2) && (p1.g == p2.g) && (p1.weights == p2.weights)

"""
    TensorNetworkSolver
    TensorNetworkSolver(; prune_by_env::Bool = true)

A struct representing a solver for tensor network problems. 
This struct serves as a specific implementation of the `AbstractTableSolver` type.
"""
@kwdef struct TensorNetworkSolver <: AbstractTableSolver
    prune_by_env::Bool = true
end

"""
    NumOfVertices

A struct representing a measure that counts the number of vertices in a graph. 
Each vertex is counted as 1.

# Fields
- None
"""
struct NumOfVertices <: AbstractMeasure end

"""
    measure(p::MISProblem, ::NumOfVertices)

Calculates the number of vertices in the given `MISProblem`.

# Arguments
- `p::MISProblem`: The problem instance containing the graph.

# Returns
- `Int`: The number of vertices in the graph.
"""
OptimalBranchingCore.measure(p::MISProblem{INT}, ::NumOfVertices) where {INT} = nv(p.g)

"""
    size_reduction(p::MISProblem{INT}, ::NumOfVertices, cl::Clause, variables::Vector) where {INT}

Calculates the size reduction for the given `MISProblem` using the number of vertices after applying the clause.

# Arguments
- `p::MISProblem{INT}`: The problem instance containing the graph.
- `cl::Clause`: The clause to be applied.
- `variables::Vector`: The variables included in the clause.

# Returns
- `sum`: The size reduction value.
"""
function OptimalBranchingCore.size_reduction(p::MISProblem{INT}, ::NumOfVertices, cl::Clause, variables::Vector) where {INT}
    return count_ones(removed_mask(INT, variables, p.g, cl))
end

"""
    D3Measure

A struct representing a measure that calculates the sum of the maximum degree minus 2 for each vertex in the graph.

# Fields
- None
"""
struct D3Measure <: AbstractMeasure end

"""
    measure(p::MISProblem, ::D3Measure)

Calculates the D3 measure for the given `MISProblem`, which is defined as the sum of 
the maximum degree of each vertex minus 2, for all vertices in the graph.

# Arguments
- `p::MISProblem`: The problem instance containing the graph.

# Returns
- `Int`: The computed D3 measure value.
"""
function OptimalBranchingCore.measure(p::MISProblem{INT}, ::D3Measure) where {INT}
    g = p.g
    if nv(g) == 0
        return 0
    else
        dg = degree(g)
        return Int(sum(max(d - 2, 0) for d in dg))
    end
end

"""
    size_reduction(p::MISProblem{INT}, ::D3Measure, cl::Clause, variables::Vector) where {INT}

Calculates the size reduction for the given `MISProblem` using the D3 measure after applying the clause.

# Arguments
- `p::MISProblem{INT}`: The problem instance containing the graph.
- `cl::Clause`: The clause to be applied.
- `variables::Vector`: The variables included in the clause.

# Returns
- `sum`: The size reduction value.
"""
function OptimalBranchingCore.size_reduction(p::MISProblem{INT}, ::D3Measure, cl::Clause, variables::Vector) where {INT}
    remove_mask = removed_mask(INT, variables, p.g, cl)
    iszero(remove_mask) && return 0
    sum = 0
    for i in 1:nv(p.g)
        deg = degree(p.g, i)
        deg <= 2 && continue
        if readbit(remove_mask, i) == 1
            sum += max(deg - 2, 0)
        else
            countneighbor = count(v -> readbit(remove_mask, v) == 0, neighbors(p.g, i)) 
            sum += max(deg - 2, 0) - max(countneighbor - 2, 0)
        end
    end
    return sum
end