@inline function advect_particle(
    method::RungeKutta2,
    p0::NTuple{N,T},
    V::NTuple{N,AbstractArray{T,N}},
    grid_vi,
    local_limits,
    dxi,
    dt,
    idx::NTuple,
) where {T,N}

    # interpolate velocity to current location
    vp0 = interp_velocity2particle(p0, grid_vi, local_limits, dxi, V, idx)

    # first advection stage x = x + v * dt * α
    p1 = first_stage(method, dt, vp0, p0)

    # interpolate velocity to new location
    vp1 = interp_velocity2particle(p1, grid_vi, local_limits, dxi, V, idx)

    # final advection step
    p2 = second_stage(method, dt, vp0, vp1, p0)

    return p2
end
