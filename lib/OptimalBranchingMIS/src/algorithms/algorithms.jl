"""
    struct MISCount

Represents the count of Maximum Independent Sets (MIS).

# Fields
- `mis_size::Int`: The size of the Maximum Independent Set.
- `mis_count::Int`: The number of Maximum Independent Sets of that size.

# Constructors
- `MISCount(mis_size::Int)`: Creates a `MISCount` with the given size and initializes the count to 1.
- `MISCount(mis_size::Int, mis_count::Int)`: Creates a `MISCount` with the specified size and count.

"""
struct MISCount{T}
    size::T
    count::Int
    MISCount(size::T) where {T} = new{T}(size, 1)
    MISCount(size::T, count::Int) where {T} = new{T}(size, count)
end

Base.:+(a::MISCount, b::MISCount) = MISCount(a.size + b.size, a.count + b.count)
Base.:+(a::MISCount{T}, b::T) where {T} = MISCount(a.size + b, a.count)
Base.:+(a::T, b::MISCount{T}) where {T} = MISCount(a + b.size, b.count)
Base.max(a::MISCount, b::MISCount) = MISCount(max(a.size, b.size), (a.count + b.count))
Base.zero(::MISCount) = MISCount(0, 1)
Base.zero(::Type{MISCount}) = MISCount(0, 1)

include("mis1.jl")
include("mis2.jl")
include("xiao2013.jl")
include("xiao2013_utils.jl")
include("xiao2021.jl")
include("xiao2021_utils.jl")
include("ip.jl")
