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
    g::SimpleGraph{Int}
end
Base.copy(p::MISProblem) = MISProblem(copy(p.g))
Base.show(io::IO, p::MISProblem) = print(io, "MISProblem($(nv(p.g)))")
Base.isempty(p::MISProblem) = nv(p.g) == 0

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

function OptimalBranchingCore.size_reduction(p::MISProblem, m::D3Measure, cl::Clause{INT}, variables::Vector) where {INT}
    vertices_removed = removed_vertices(variables, p.g, cl)
    sum = 0
    for v in vertices_removed
        sum += max(degree(p.g, v) - 2, 0)
    end
    vertices_removed_neighbors = setdiff(mapreduce(v -> neighbors(p.g, v), ∪, vertices_removed), vertices_removed)
    for v in vertices_removed_neighbors
        sum += max(degree(p.g, v) - 2) - max(degree(p.g, v) - 2 - count(vx -> vx ∈ vertices_removed, neighbors(p.g, v)), 0)
    end
    return sum
end
