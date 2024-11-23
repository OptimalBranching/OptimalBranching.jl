export subcovers

function all_clauses_naive(n::Int, bss::AbstractVector{Vector{INT}}) where INT
    allclauses = Vector{Clause{INT}}()
    for ids in Iterators.product([0:length(bss[i]) for i in 1:length(bss)]...)
        masks = [ids...]
        cbs = [bss[i][masks[i]] for i in 1:length(bss) if masks[i] != 0]
        if length(cbs) > 0
            ccbs = clause(n::Int, cbs)
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

function subcovers(tbl::BranchingTable{INT}) where{INT}
    return subcovers(tbl.bit_length, tbl.table)
end