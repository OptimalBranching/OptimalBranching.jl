using Yao, OMEinsum, OptimalBranchingSTN

qft = chain(4, chain(4, i==j ? put(i=>H) : control(4, i, j=>shift(2π/(2^(j-i+1)))) for j in i:4) for i = 1:4)

qft_net = yao2einsum(chain(qft, chain(4, [put(4, i=>X) for i in 1:4]), qft'), initial_state = Dict([i=>zero_state(1) for i=1:4]), final_state = Dict([i=>zero_state(1) for i=1:4]), optimizer = GreedyMethod())

dense_contract(qft_net)[]