export AbstractBranching, AbstractMeasure, AbstractSelector, AbstractPuner, AbstractSetCoverSolver, AbstractReducer
export NoReducer, NoPuner

abstract type AbstractBranching end

abstract type AbstractMeasure end

abstract type AbstractReducer end
struct NoReducer <: AbstractReducer end

abstract type AbstractSelector end

abstract type AbstractPuner end
struct NoPuner <: AbstractPuner end

abstract type AbstractSetCoverSolver end

