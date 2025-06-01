"""
    mutable struct MISProblem{INT <: Integer} <: AbstractProblem

Represents a Maximum Independent Set (MIS) problem.

# Fields
- `g::SimpleGraph`: The graph associated with the MIS problem.

# Methods
- `copy(p::MISProblem)`: Creates a copy of the given `MISProblem`.
- `Base.show(io::IO, p::MISProblem)`: Displays the number of vertices in the `MISProblem`.

"""
mutable struct MISProblem{INT <: Integer} <: AbstractProblem
    g::SimpleGraph{Int}
    function MISProblem(g::SimpleGraph{Int})
        new{BitBasis.longinttype(nv(g), 2)}(g)
    end
end
Base.copy(p::MISProblem) = MISProblem(copy(p.g))
Base.show(io::IO, p::MISProblem) = print(io, "MISProblem($(nv(p.g)))")
OptimalBranchingCore.has_zero_size(p::MISProblem) = nv(p.g) == 0
Base.:(==)(p1::MISProblem{T1}, p2::MISProblem{T2}) where {T1, T2} = (T1 == T2) && (p1.g == p2.g)

"""
    mutable struct MWISProblem{INT <: Integer} <: AbstractProblem

Represents a Maximum Weighted Independent Set (MWIS) problem.

# Fields
- `g::SimpleGraph`: The graph associated with the MWIS problem.
- `weights::Vector`: The weights of the vertices in the graph.

# Methods
- `copy(p::MWISProblem)`: Creates a copy of the given `MWISProblem`.
- `Base.show(io::IO, p::MWISProblem)`: Displays the number of vertices in the `MWISProblem`.

"""
mutable struct MWISProblem{INT <: Integer} <: AbstractProblem
    g::SimpleGraph{Int}
    weights::Vector
    function MWISProblem(g::SimpleGraph{Int}, weights::Vector)
        new{BitBasis.longinttype(nv(g), 2)}(g, weights)
    end
end
Base.copy(p::MWISProblem) = MWISProblem(copy(p.g), copy(p.weights))
Base.show(io::IO, p::MWISProblem) = print(io, "MWISProblem($(nv(p.g)))")
OptimalBranchingCore.has_zero_size(p::MWISProblem) = nv(p.g) == 0
Base.:(==)(p1::MWISProblem{T1}, p2::MWISProblem{T2}) where {T1, T2} = 
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
    measure(p::Union{MISProblem, MWISProblem}, ::NumOfVertices)

Calculates the number of vertices in the given `MISProblem` or `MWISProblem`.

# Arguments
- `p::Union{MISProblem, MWISProblem}`: The problem instance containing the graph.

# Returns
- `Int`: The number of vertices in the graph.
"""
OptimalBranchingCore.measure(p::Union{MISProblem{INT}, MWISProblem{INT}}, ::NumOfVertices) where {INT} = nv(p.g)
function OptimalBranchingCore.size_reduction(p::Union{MISProblem{INT}, MWISProblem{INT}}, ::NumOfVertices, cl::Clause, variables::Vector) where {INT}
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
    measure(p::Union{MISProblem, MWISProblem}, ::D3Measure)

Calculates the D3 measure for the given `MISProblem` or `MWISProblem`, which is defined as the sum of 
the maximum degree of each vertex minus 2, for all vertices in the graph.

# Arguments
- `p::Union{MISProblem, MWISProblem}`: The problem instance containing the graph.

# Returns
- `Int`: The computed D3 measure value.
"""
function OptimalBranchingCore.measure(p::Union{MISProblem{INT}, MWISProblem{INT}}, ::D3Measure) where {INT}
    g = p.g
    if nv(g) == 0
        return 0
    else
        dg = degree(g)
        return Int(sum(max(d - 2, 0) for d in dg))
    end
end

function OptimalBranchingCore.size_reduction(p::Union{MISProblem{INT}, MWISProblem{INT}}, ::D3Measure, cl::Clause, variables::Vector) where {INT}
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
