"""
    mis_size(g::AbstractGraph; bs::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure()), reducer::AbstractReducer = MISReducer())

Calculate the size of the Maximum Independent Set (MIS) for a given graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MIS size is to be calculated.
- `bs::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundarySelector(2)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MISReducer`.

### Returns
- An integer representing the size of the Maximum Independent Set for the given graph.
"""
function mis_size(g::AbstractGraph; bs::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure()), reducer=MISReducer())
    p = MISProblem(g)
    res = reduce_and_branch(p, bs, reducer, MaxSize)
    return res.size
end

"""
    mis_branch_count(g::AbstractGraph; bs::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure()), reducer=MISReducer())

Calculate the size and the number of branches of the Maximum Independent Set (MIS) for a given graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MIS size and the number of branches are to be calculated.
- `bs::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundarySelector(2)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MISReducer`.

### Returns
- A tuple `(size, count)` where `size` is the size of the Maximum Independent Set and `count` is the number of branches.
"""
function mis_branch_count(g::AbstractGraph; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundarySelector(2), measure=D3Measure()), reducer=MISReducer())
    p = MISProblem(g)
    res = reduce_and_branch(p, branching_strategy, reducer, MaxSizeBranchCount)
    return (res.size, res.count)
end