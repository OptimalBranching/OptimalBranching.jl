mutable struct MISProblem <: AbstractProblem
    g::SimpleGraph
end
copy(p::MISProblem) = MISProblem(copy(p.g))
Base.show(io::IO, p::MISProblem) = print(io, "MISProblem($(nv(p.g)))")

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

struct TensorNetworkSolver <: AbstractTableSolver end

struct NumOfVertices <: AbstractMeasure end # each vertex is counted as 1
OptimalBranchingCore.measure(p::MISProblem, ::NumOfVertices) = nv(p.g)

struct D3Measure <: AbstractMeasure end # n = sum max{d - 2, 0}
function OptimalBranchingCore.measure(p::MISProblem, ::D3Measure)
    g = p.g
    if nv(g) == 0
        return 0
    else
        dg = degree(g)
        return Int(sum(max(d - 2, 0) for d in dg))
    end
end