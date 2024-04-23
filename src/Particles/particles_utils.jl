@inline function init_cell_arrays(particles::Particles, ::Val{N}) where {N}
    return ntuple(
        _ -> @fill(
            0.0, size(particles.coords[1])..., celldims = (cellsize(particles.index))
        ),
        Val(N),
    )
end

@inline function cell_array(x::T, ncells::NTuple{N,Integer}, ni::Vararg{Any,N}) where {T,N}
    @fill(x, ni..., celldims = ncells, eltype = T)
end

## random particles initialization 

function init_particles(backend, nxcell, max_xcell, min_xcell, x, y, dx, dy, nx, ny)
    return init_particles(backend, nxcell, max_xcell, min_xcell, (x, y), (dx, dy), (nx, ny))
end

function init_particles(
    backend, nxcell, max_xcell, min_xcell, x, y, z, dx, dy, dz, nx, ny, nz
)
    return init_particles(
        backend, nxcell, max_xcell, min_xcell, (x, y, z), (dx, dy, dz), (nx, ny, nz)
    )
end

function init_particles(
    backend,
    nxcell,
    max_xcell,
    min_xcell,
    coords::NTuple{N,AbstractArray},
    dxᵢ::NTuple{N,T},
    nᵢ::NTuple{N,I},
) where {N,T,I}
    ncells = prod(nᵢ)
    np = max_xcell * ncells
    pxᵢ = ntuple(_ -> @rand(nᵢ..., celldims = (max_xcell,)), Val(N))
    index = @fill(false, nᵢ..., celldims = (max_xcell,), eltype = Bool)

    @parallel_indices (I...) function fill_coords_index(
        pxᵢ::NTuple{N,T}, index, coords, dxᵢ, nxcell, max_xcell
    ) where {N,T}
        # lower-left corner of the cell
        x0ᵢ = ntuple(Val(N)) do ndim
            coords[ndim][I[ndim]]
        end

        # fill index array
        for l in 1:max_xcell
            if l ≤ nxcell
                ntuple(Val(N)) do ndim
                    @cell pxᵢ[ndim][l, I...] =
                        x0ᵢ[ndim] + dxᵢ[ndim] * (@cell(pxᵢ[ndim][l, I...]) * 0.9 + 0.05)
                end
                @cell index[l, I...] = true

            else
                ntuple(Val(N)) do ndim
                    @cell pxᵢ[ndim][l, I...] = NaN
                end
            end
        end
        return nothing
    end

    @parallel (@idx nᵢ) fill_coords_index(pxᵢ, index, coords, dxᵢ, nxcell, max_xcell)

    return Particles(backend, pxᵢ, index, nxcell, max_xcell, min_xcell, np)
end

# function get_cell(xi::Union{SVector{N,T},NTuple{N,T}}, dxi::NTuple{N,T}) where {N,T<:Real}
#     ntuple(Val(N)) do i
#         Base.@_inline_meta
#         abs(Int64(xi[i] ÷ dxi[i])) + 1
#     end
# end
