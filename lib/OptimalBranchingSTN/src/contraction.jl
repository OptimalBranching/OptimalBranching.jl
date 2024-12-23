using OMEinsum: drop_slicedim, take_slice

function dense_contract(tn::TensorNetwork)
    return tn.code(tn.tensors...)
end

# consider a naive implementation, with a given tensor network with sparse tensors.
# we simply split fix the value of the indices, without any set covering
function sparse_contract_naive(
    tn::TensorNetwork,
    filling_rate, # the minimum filling rate of the sparse tensor to be considered
    dim # the minimum dimension of the sparse tensor to be considered
    )  

    return nothing
end

# branch on the i-th tensor
function branch_naive(tn::TensorNetwork, i::Int)
    tensor_i = tn.tensors[i]
    nonzeros = nonzero_elements(tensor_i)

    branches = TensorNetwork[]

    rawcode = OMEinsum.flatten(tn.code)
    sliced_eins = drop_slicedim(tn.code, rawcode.ixs[i])

    for (id, value) in nonzeros
        slicemap = Dict(rawcode.ixs[i][j]=>id.I[j] for j in 1:length(id.I))
        new_tensors = ntuple(j->take_slice(tn.tensors[j], rawcode.ixs[j], slicemap), length(tn.tensors))
        push!(branches, TensorNetwork(sliced_eins, [new_tensors...]))
    end
    return branches
end