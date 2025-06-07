"""
    MaxSize

A struct representing the maximum size of a result. (actually a tropical int)

### Fields
- `size`: The maximum size value.

### Constructors
- `MaxSize(size)`: Creates a `MaxSize` instance with the specified size.
"""
struct MaxSize{T}
    size::T
    MaxSize(size::T) where {T} = new{T}(size)
end

Base.:+(a::MaxSize, b::MaxSize) = MaxSize(max(a.size, b.size))
Base.:*(a::MaxSize, b::MaxSize) = MaxSize(a.size + b.size)
Base.zero(::Type{MaxSize}) = MaxSize(0)

"""
    struct MaxSizeBranchCount

Reture both the max size of the results and number of branches.

# Fields
- `size`: The max size of the results.
- `count::Int`: The number of branches of that size.

# Constructors
- `MaxSizeBranchCount(size)`: Creates a `MaxSizeBranchCount` with the given size and initializes the count to 1.
- `MaxSizeBranchCount(size, count::Int)`: Creates a `MaxSizeBranchCount` with the specified size and count.

"""
struct MaxSizeBranchCount{T}
    size::T
    count::Int
    MaxSizeBranchCount(size::T) where {T} = new{T}(size, 1)
    MaxSizeBranchCount(size::T, count::Int) where {T} = new{T}(size, count)
end

Base.:+(a::MaxSizeBranchCount, b::MaxSizeBranchCount) = MaxSizeBranchCount(max(a.size, b.size), a.count + b.count)
Base.:*(a::MaxSizeBranchCount, b::MaxSizeBranchCount) = MaxSizeBranchCount(a.size + b.size, (a.count * b.count))
Base.zero(::Type{MaxSizeBranchCount}) = MaxSizeBranchCount(0, 1)
