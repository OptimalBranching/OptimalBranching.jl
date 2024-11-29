"""
    Clause{INT <: Integer}

A Clause is conjunction of literals, which is specified by a pair of bit strings.
The type parameter `INT` is the integer type for storing the bit strings.

### Fields
- `mask`: A bit string that indicates the variables involved in the clause.
- `val`: A bit string that indicates the positive literals in the clause.

### Examples
To check if a bit string satisfies a clause, use `OptimalBranchingCore.covered_by`.

```jldoctest
julia> using OptimalBranchingCore

julia> clause = Clause(0b1110, 0b1010)
Clause{UInt8}: #2 ∧ ¬#3 ∧ #4

julia> OptimalBranchingCore.covered_by(0b1110, clause)
false

julia> OptimalBranchingCore.covered_by(0b1010, clause)
true
```
"""
struct Clause{INT <: Integer}
    mask::INT
    val::INT
    function Clause(mask::INT, val::INT) where INT <: Integer
        new{INT}(mask, val & mask)
    end
end

function Base.show(io::IO, c::Clause{INT}) where INT
    print(io, "$(typeof(c)): " * join([iszero(readbit(c.val, i)) ? "¬#$i" : "#$i" for i = 1:bsizeof(INT) if readbit(c.mask, i) == 1], " ∧ "))
end
function booleans(n::Int)
    C = (n + 63) ÷ 64
    INT = LongLongUInt{C}
    return [Clause(bmask(INT, i), bmask(INT, i)) for i=1:n]
end
∧(x::Clause, xs::Clause...) = Clause(reduce(|, getfield.(xs, :mask); init=x.mask), reduce(|, getfield.(xs, :val); init=x.val))
¬(x::Clause) = Clause(x.mask, flip(x.val, x.mask))

function BitBasis.bdistance(c1::Clause{INT}, c2::Clause{INT}) where INT <: Integer
    b1 = c1.val & c1.mask & c2.mask
    b2 = c2.val & c1.mask & c2.mask
    return bdistance(b1, b2)
end

function BitBasis.bdistance(c::Clause{INT}, b::INT) where INT <: Integer
    b1 = b & c.mask
    c1 = c.val & c.mask
    return bdistance(b1, c1)
end

"""
    covered_by(a::LongLongUInt, b::LongLongUInt, mask::LongLongUInt)

Check if `a` is covered by `b` with `mask`. The function returns `true` if and only if `a` and `b` are the same when masked by `mask`.
"""
function covered_by(a, b, mask)
    return (a & mask) == (b & mask)
end

"""
    covered_by(a::LongLongUInt, clause::Clause)

Check if `a` is covered by the clause. The function returns `true` if and only if `a` and `clause.val` are the same when masked by `clause.mask`.
"""
covered_by(a, clause::Clause) = covered_by(a, clause.val, clause.mask)

function covered_by(as::AbstractArray, clause::Clause)
    return [covered_by(a, clause) for a in as]
end

# Returns the indices of the bit strings that are covered by the clause.
function covered_items(bitstrings, clause::Clause)
    return findall(b -> any(covered_by(b, clause)), bitstrings)
end

# Flip all bits in `b`, `n` is the number of bits
function flip_all(n::Int, b::INT) where INT <: Integer
    return flip(b, bmask(INT, 1:n))
end

# Return a clause that covers all the bit strings.
function cover_clause(n::Int, bitstrings::AbstractVector{INT}) where INT
    mask = bmask(INT, 1:n)
    for i in 1:length(bitstrings) - 1
        mask &= bitstrings[i] ⊻ flip_all(n, bitstrings[i+1])
    end
    val = bitstrings[1] & mask
    return Clause(mask, val)
end

function gather2(n::Int, c1::Clause{INT}, c2::Clause{INT}) where INT
    b1 = c1.val & c1.mask
    b2 = c2.val & c2.mask
    mask = (b1 ⊻ flip_all(n, b2)) & c1.mask & c2.mask
    val = b1 & mask
    return Clause(mask, val)
end

"""
    DNF{INT}

A data structure representing a Disjunctive Normal Form (DNF) expression. A DNF is a logical formula that is a disjunction of one or more conjunctions of literals. 

# Fields
- `clauses::Vector{Clause{INT}}`: A vector of `Clause` objects representing the individual clauses in the DNF.
"""
struct DNF{INT}
    clauses::Vector{Clause{INT}}
end

DNF(c::Clause{INT}, cs::Clause{INT}...) where {INT} = DNF([c, cs...])
Base.:(==)(x::DNF, y::DNF) = x.clauses == y.clauses
Base.length(x::DNF) = length(x.clauses)

function covered_by(s::Integer, dnf::DNF)
    any(c->covered_by(s, c), dnf.clauses)
end
