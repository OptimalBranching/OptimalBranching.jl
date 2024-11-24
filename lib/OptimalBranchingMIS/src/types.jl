"""
    mutable struct MISProblem <: AbstractProblem

Represents a Maximum Independent Set (MIS) problem.

# Fields
- `g::SimpleGraph`: The graph associated with the MIS problem.

# Methods
- `copy(p::MISProblem)`: Creates a copy of the given `MISProblem`.
- `Base.show(io::IO, p::MISProblem)`: Displays the number of vertices in the `MISProblem`.

"""
mutable struct MISProblem <: AbstractProblem
    g::SimpleGraph
end
copy(p::MISProblem) = MISProblem(copy(p.g))
Base.show(io::IO, p::MISProblem) = print(io, "MISProblem($(nv(p.g)))")

"""
    struct MISSize <: AbstractResult

Represents the size of a Maximum Independent Set (MIS).

# Fields
- `mis_size::Int`: The size of the Maximum Independent Set.

"""
struct MISSize <: AbstractResult
    mis_size::Int
end

Base.:+(a::MISSize, b::MISSize) = MISSize(a.mis_size + b.mis_size)
Base.:+(a::MISSize, b::Int) = MISSize(a.mis_size + b)
Base.:+(a::Int, b::MISSize) = MISSize(a + b.mis_size)
Base.max(a::MISSize, b::MISSize) = MISSize(max(a.mis_size, b.mis_size))
Base.max(a::MISSize, b::Int) = MISSize(max(a.mis_size, b))
Base.max(a::Int, b::MISSize) = MISSize(max(a, b.mis_size))
Base.zero(::MISSize) = MISSize(0)
Base.zero(::Type{MISSize}) = MISSize(0)

"""
    struct MISCount <: AbstractResult

Represents the count of Maximum Independent Sets (MIS).

# Fields
- `mis_size::Int`: The size of the Maximum Independent Set.
- `mis_count::Int`: The number of Maximum Independent Sets of that size.

# Constructors
- `MISCount(mis_size::Int)`: Creates a `MISCount` with the given size and initializes the count to 1.
- `MISCount(mis_size::Int, mis_count::Int)`: Creates a `MISCount` with the specified size and count.

"""
struct MISCount <: AbstractResult
    mis_size::Int
    mis_count::Int
    MISCount(mis_size::Int) = new(mis_size, 1)
    MISCount(mis_size::Int, mis_count::Int) = new(mis_size, mis_count)
end

Base.:+(a::MISCount, b::MISCount) = MISCount(a.mis_size + b.mis_size, a.mis_count + b.mis_count)
Base.:+(a::MISCount, b::Int) = MISCount(a.mis_size + b, a.mis_count)
Base.:+(a::Int, b::MISCount) = MISCount(a + b.mis_size, b.mis_count)
Base.max(a::MISCount, b::MISCount) = MISCount(max(a.mis_size, b.mis_size), (a.mis_count + b.mis_count))
Base.zero(::MISCount) = MISCount(0, 1)
Base.zero(::Type{MISCount}) = MISCount(0, 1)

"""
    TensorNetworkSolver

A struct representing a solver for tensor network problems. 
This struct serves as a specific implementation of the `AbstractTableSolver` type.
"""
struct TensorNetworkSolver <: AbstractTableSolver end

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
OptimalBranchingCore.measure(p::MISProblem, ::NumOfVertices) = nv(p.g)

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
function OptimalBranchingCore.measure(p::MISProblem, ::D3Measure)
    g = p.g
    if nv(g) == 0
        return 0
    else
        dg = degree(g)
        return Int(sum(max(d - 2, 0) for d in dg))
    end
end