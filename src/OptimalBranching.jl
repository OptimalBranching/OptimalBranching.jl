module OptimalBranching

using Reexport
@reexport using OptimalBranchingMIS

using OptimalBranchingCore

export BranchingStrategy, IPSolver, LPSolver
export NoReducer
export MaxSize, MaxSizeBranchCount

export reduce_and_branch

end
