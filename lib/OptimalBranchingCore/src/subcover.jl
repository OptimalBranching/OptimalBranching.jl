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
    n, bss = tbl.bit_length, tbl.table
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