"""
    BranchingTable{INT <: Integer}

A list of groupped bitstrings, which is used for designing the branching rule.
A valid branching rule, which is represented by a logic expression in Disjunctive Normal Form (DNF), should cover at least one bitstring from each group,
where by `cover`, we mean there exists at least one bitstring in the group that satisfies the logic expression. Please check [`covered_by`](@ref) for more details.

### Fields
- `bit_length::Int`: The length of the bit string.
- `table::Vector{Vector{INT}}`: The list of groupped bitstrings used for branching, where each group is a vector of bitstrings. The bitstrings uses `INT` type to store the bitstring.
"""
struct BranchingTable{INT <: Integer}
    bit_length::Int
    table::Vector{Vector{INT}}
end

function BranchingTable(n::Int, arr::AbstractVector{<:AbstractVector})
    @assert all(x->all(v->length(v) == n, x), arr)
    T = LongLongUInt{(n-1) ÷ 64 + 1}
    return BranchingTable(n, [_vec2int.(T, x) for x in arr])
end
# encode a bit vector to and integer
function _vec2int(::Type{T}, v::AbstractVector) where T <: Integer
    res = zero(T)
    for i in 1:length(v)
        res |= T(v[i]) << (i-1)
    end
    return res
end

nbits(t::BranchingTable) = t.bit_length
Base.:(==)(t1::BranchingTable, t2::BranchingTable) = all(x -> Set(x[1]) == Set(x[2]), zip(t1.table, t2.table))
function Base.show(io::IO, t::BranchingTable{INT}) where INT
    println(io, "BranchingTable{$INT}")
    for (i, row) in enumerate(t.table)
        print(io, join(["$(bitstring(r)[end-nbits(t)+1:end])" for r in row], ", "))
        i < length(t.table) && println(io)
    end
end
Base.show(io::IO, ::MIME"text/plain", t::BranchingTable) = show(io, t)
Base.copy(t::BranchingTable) = BranchingTable(t.bit_length, copy(t.table))

"""
    covered_by(t::BranchingTable, dnf::DNF)

Check if the branching table `t` is covered by the logic expression `dnf`.
Returns `true` if there exists at least one bitstring in each group of `t` that satisfies `dnf`, `false` otherwise.
"""
function covered_by(t::BranchingTable, dnf::DNF)
    all(x->any(y->covered_by(y, dnf), x), t.table)
end