module JustPIC

# using ImplicitGlobalGrid
using MPI: MPI

abstract type AbstractBackend end
struct CPUBackend <: AbstractBackend end
struct AMDGPUBackend <: AbstractBackend end

export TA

function CA end

TA() = Array
TA(::Type{CPUBackend}) = Array

include("particles.jl")
export AbstractParticles, Particles, MarkerChain, PassiveMarkers, cell_index, cell_length

include("Advection/types.jl")
export AbstractAdvectionIntegrator, Euler, RungeKutta2

include("JustPIC_CPU.jl")

end # module
