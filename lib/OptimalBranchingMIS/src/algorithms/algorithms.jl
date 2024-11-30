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
struct MISCount
    size::Int
    count::Int
    MISCount(size::Int) = new(size, 1)
    MISCount(size::Int, count::Int) = new(size, count)
end

Base.:+(a::MISCount, b::MISCount) = MISCount(a.size + b.size, a.count + b.count)
Base.:+(a::MISCount, b::Int) = MISCount(a.size + b, a.count)
Base.:+(a::Int, b::MISCount) = MISCount(a + b.size, b.count)
Base.max(a::MISCount, b::MISCount) = MISCount(max(a.size, b.size), (a.count + b.count))
Base.zero(::MISCount) = MISCount(0, 1)
Base.zero(::Type{MISCount}) = MISCount(0, 1)

include("mis1.jl")
include("mis2.jl")
include("xiao2013.jl")
include("xiao2013_utils.jl")

