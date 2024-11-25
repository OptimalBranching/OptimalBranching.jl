export subcovers

function all_clauses_naive(n::Int, bss::AbstractVector{Vector{INT}}) where INT
    allclauses = Vector{Clause{INT}}()
    for ids in Iterators.product([0:length(bss[i]) for i in 1:length(bss)]...)
        masks = [ids...]
        cbs = [bss[i][masks[i]] for i in 1:length(bss) if masks[i] != 0]
        if length(cbs) > 0
            ccbs = cover_clause(n::Int, cbs)
            if !(ccbs in allclauses) && (ccbs.mask != 0)
                push!(allclauses, ccbs)
            end
        end
    end
    return allclauses
end


function subcovers_naive(n::Int, bs::Union{Vector{INT}, AbstractVector{Vector{INT}}}) where {INT}
    allclauses = all_clauses_naive(n, bs)
    allcovers = Vector{SubCover{INT}}()
    for (i, c) in enumerate(allclauses)
        ids = covered_items(bs, c)
        push!(allcovers, SubCover(n, ids, c))
    end
    return allcovers
end

function subcovers_naive(tbl::BranchingTable{INT}) where{INT}
    return subcovers_naive(tbl.bit_length, tbl.table)
end

"""
    subcovers(n::Int, bss::AbstractVector{Vector{INT}}) where {INT}

Generates a set of subcovers from the given bit strings.

# Arguments
- `n::Int`: The length of the bit strings.
- `bss::AbstractVector{Vector{INT}}`: A collection of vectors containing bit strings.

# Returns
- `Vector{SubCover{INT}}`: A vector of `SubCover` objects representing the generated subcovers.

# Description
This function concatenates the input vectors of bit strings and iteratively generates clauses. It maintains a set of all unique clauses and uses a temporary list to explore new clauses formed by combining existing ones. The resulting subcovers are created based on the covered items for each clause.

"""
function subcovers(n::Int, bss::AbstractVector{Vector{INT}}) where {INT}
    bs = vcat(bss...)
    all_clauses = Set{Clause{INT}}()
    temp_clauses = [Clause(bmask(INT, 1:n), bs[i]) for i in 1:length(bs)]
    while !isempty(temp_clauses)
        c = pop!(temp_clauses)
        if !(c in all_clauses)
            push!(all_clauses, c)
            idc = Set(covered_items(bss, c))
            for i in 1:length(bss)
                if i ∉ idc                
                    for b in bss[i]
                        c_new = gather2(n, c, Clause(bmask(INT, 1:n), b))
                        if (c_new != c) && c_new.mask != 0
                            push!(temp_clauses, c_new)
                        end
                    end
                end
            end
        end
    end

    allcovers = [SubCover(n, covered_items(bss, c), c) for c in all_clauses]

    return allcovers
end

"""
    subcovers(tbl::BranchingTable{INT}) where {INT}

Generates subcovers from a branching table.

# Arguments
- `tbl::BranchingTable{INT}`: The branching table containing bit strings.

# Returns
- `Vector{SubCover{INT}}`: A vector of `SubCover` objects generated from the branching table.

# Description
This function calls the `subcovers` function with the bit length and table from the provided branching table to generate the corresponding subcovers.

"""
function subcovers(tbl::BranchingTable{INT}) where {INT}
    return subcovers(tbl.bit_length, tbl.table)
end