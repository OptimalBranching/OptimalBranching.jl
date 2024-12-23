using OMEinsum

simple_net_code = optein"ijkl, i, j, k, l -> "
tensors = [zeros(Float64, 2, 2, 2, 2), rand(2), rand(2), rand(2), rand(2)]
tensors[1][1] = 1.0
tensors[1][10] = 1.0

simple_net = TensorNetwork(simple_net_code, tensors)

