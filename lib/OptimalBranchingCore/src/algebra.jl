"""
    MaxSize

A struct representing the maximum size of a result. (actually a tropical int)

### Fields
- `size::Int`: The maximum size value.

### Constructors
- `MaxSize(size::Int)`: Creates a `MaxSize` instance with the specified size.
"""
struct MaxSize
    size::Int
    MaxSize(size::Int) = new(size)
end

Base.:+(a::MaxSize, b::MaxSize) = MaxSize(max(a.size, b.size))
Base.:*(a::MaxSize, b::MaxSize) = MaxSize(a.size + b.size)
Base.zero(::Type{MaxSize}) = MaxSize(0)

"""
    struct MaxSizeBranchCount

Reture both the max size of the results and number of branches.

# Fields
- `size::Int`: The max size of the results.
- `count::Int`: The number of branches of that size.

# Constructors
- `MaxSizeBranchCount(size::Int)`: Creates a `MaxSizeBranchCount` with the given size and initializes the count to 1.
- `MaxSizeBranchCount(size::Int, count::Int)`: Creates a `MaxSizeBranchCount` with the specified size and count.

"""
struct MaxSizeBranchCount
    size::Int
    count::Int
    MaxSizeBranchCount(size::Int) = new(size, 1)
    MaxSizeBranchCount(size::Int, count::Int) = new(size, count)
end

Base.:+(a::MaxSizeBranchCount, b::MaxSizeBranchCount) = MaxSizeBranchCount(max(a.size, b.size), a.count + b.count)
Base.:*(a::MaxSizeBranchCount, b::MaxSizeBranchCount) = MaxSizeBranchCount(a.size + b.size, (a.count * b.count))
Base.zero(::Type{MaxSizeBranchCount}) = MaxSizeBranchCount(0, 1)
