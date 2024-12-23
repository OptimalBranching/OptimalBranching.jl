function nonzero_elements(tensor::AbstractArray{T}) where T
    nonzeros = Tuple{CartesianIndex, T}[]
    for id in CartesianIndices(tensor)
        if !isapprox(tensor[id], zero(T))
            push!(nonzeros, (id, tensor[id]))
        end
    end
    return nonzeros
end