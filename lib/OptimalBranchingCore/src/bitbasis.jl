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

function clause_string(c::Clause{INT}) where INT
    join([iszero(readbit(c.val, i)) ? "¬#$i" : "#$i" for i = 1:bsizeof(INT) if readbit(c.mask, i) == 1], " ∧ ")
end

function Base.show(io::IO, c::Clause{INT}) where INT
    print(io, "$(typeof(c)): " * clause_string(c))
end
function booleans(n::Int)
    INT = BitBasis.longinttype(n, 2)
    return [Clause(bmask(INT, i), bmask(INT, i)) for i=1:n]
end
∧(x::Clause, xs::Clause...) = Clause(reduce(|, getfield.(xs, :mask); init=x.mask), reduce(|, getfield.(xs, :val); init=x.val))
¬(x::Clause) = Clause(x.mask, flip(x.val, x.mask))
# The number of literals in the clause
Base.length(clause::Clause) = count_ones(clause.mask)

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
    literals(c::Clause)

Return all literals in the clause.
"""
literals(c::Clause) = [Clause(readbit(c.mask, i), readbit(c.val, i)) for i=1:bsizeof(c.mask) if readbit(c.mask, i) == 1]
"""
    is_true_literal(c::Clause)

Check if the clause is a true literal.
"""
is_true_literal(c::Clause) = count_ones(c.mask) == 1 && all(i->readbit(c.val, i) == readbit(c.mask, i), 1:bsizeof(c.mask))
"""
    is_false_literal(c::Clause)

Check if the clause is a false literal.
"""
is_false_literal(c::Clause) = count_ones(c.mask) == 1 && iszero(c.val)

# Flip all bits in `b`, `n` is the number of bits
function flip_all(n::Int, b::INT) where INT <: Integer
    return flip(b, bmask(INT, 1:n))
end

"""
    covered_by(a::Integer, clause_or_dnf)

Check if `a` is covered by the logic expression `clause_or_dnf`.

### Arguments
- `a`: A bit string.
- `clause_or_dnf`: Logic expression, which can be a [`Clause`](@ref) object or a [`DNF`](@ref) object.

### Returns
`true` if `a` satisfies `clause_or_dnf`, `false` otherwise.
"""
function covered_by(a::Integer, clause::Clause)
    return (a & clause.mask) == (clause.val & clause.mask)
end

"""
    DNF{INT}

A data structure representing a logic expression in Disjunctive Normal Form (DNF), which is a disjunction of one or more conjunctions of literals.
In OptimalBranchingCore, a DNF is used to represent the branching rule.

# Fields
- `clauses::Vector{Clause{INT}}`: A vector of `Clause` objects.
"""
struct DNF{INT}
    clauses::Vector{Clause{INT}}
end

DNF(c::Clause{INT}, cs::Clause{INT}...) where {INT} = DNF([c, cs...])
Base.:(==)(x::DNF, y::DNF) = Set(x.clauses) == Set(y.clauses)
Base.length(x::DNF) = length(x.clauses)

Base.show(io::IO, dnf::DNF{INT}) where {INT} = print(io, "DNF{$INT}: " * join(["($(clause_string(c)))" for c in dnf.clauses], " ∨ "))

function covered_by(s::Integer, dnf::DNF)
    any(c->covered_by(s, c), dnf.clauses)
end