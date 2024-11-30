"""
    BranchingTable{INT}

A table of branching configurations. The table is a vector of vectors of `INT`. Type parameters are:
- `INT`: The integer type for storing bit strings.

# Fields
- `bit_length::Int`: The length of the bit string.
- `table::Vector{Vector{INT}}`: The table of bitstrings used for branching.

To cover the branching table, at least one clause in each row must be satisfied.
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

function covered_by(t::BranchingTable, dnf::DNF)
    all(x->any(y->covered_by(y, dnf), x), t.table)
end

"""
    AbstractTableSolver

An abstract type for the strategy of obtaining the branching table.
"""
abstract type AbstractTableSolver end

"""
    branching_table(problem::AbstractProblem, table_solver::AbstractTableSolver, variables::Vector{Int})

Obtains the branching table for a given problem using a specified table solver.

### Arguments
- `problem`: The problem instance.
- `table_solver`: The table solver, which is a subtype of [`AbstractTableSolver`](@ref).
- `variables`: A vector of indices of the variables to be considered for the branching table.

### Returns
A branching table, which is a subtype of [`AbstractBranchingTable`](@ref).
"""
function branching_table end