export AbstractBranching, AbstractMeasure, AbstractSelector, AbstractPuner, AbstractSetCoverSolver, AbstractReducer, AbstractProblem
export NoReducer, NoPuner
export reduce!, pune!

abstract type AbstractBranching end

abstract type AbstractMeasure end

abstract type AbstractReducer end
struct NoReducer <: AbstractReducer end
function reduce!(problem::P, ::NoReducer) where P <: AbstractProblem return problem end

abstract type AbstractSelector end

abstract type AbstractPuner end
struct NoPuner <: AbstractPuner end
function pune!(bt::BranchingTable, problem::P, ::NoPuner, measure::M) where {P <: AbstractProblem, M <: AbstractMeasure} return bt end

abstract type AbstractSetCoverSolver end

abstract type AbstractProblem end