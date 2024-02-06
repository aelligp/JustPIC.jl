function resample!(chain::MarkerChain)

    # resampling launch kernel
    @parallel_indices (i) function resample!(
        coords, cell_vertices, index, min_xcell, max_xcell, dx_cells
    )
        resample_cell!(coords, cell_vertices, index, min_xcell, max_xcell, dx_cells, i)
        return nothing
    end

    (; coords, index, cell_vertices, min_xcell, max_xcell) = chain
    nx = length(cell_vertices) - 1
    dx_cells = cell_length(chain) 
    
    # call kernel
    @parallel (1:nx) resample!(coords, cell_vertices, index, min_xcell, max_xcell, dx_cells)
    return nothing
end

function resample_cell!(
    coords::NTuple{2, T}, cell_vertices, index, min_xcell, max_xcell, dx_cells, I
) where T

    # cell particles coordinates
    x_cell, y_cell = coords[1][I], coords[2][I]
    px, py = coords[1], coords[2]

    cell_vertex = cell_vertices[I]
    # number of particles in the cell
    np = count(index[I])
    # dx of the new chain
    dx_chain = dx_cells / (np + 1)
    # resample the cell if the number of particles is  
    # less than min_xcell or it is too distorted
    do_resampling = (np < min_xcell) * isdistorded(x_cell, dx_chain)

    if do_resampling
        # lower-left corner of the cell
        x0 = cell_vertex
        # fill index array
        for ip in 1:min_xcell
            # x query point
            @cell px[ip, I] = xq = x0 + dx_chain * ip
            # interpolated y coordinated
            yq = if 1 < I < length(x_cell) 
                # inner cells; this is true (ncells-2) consecutive times
                interp1D_inner(xq, x_cell, y_cell, coords, I)
            else 
                # first and last cells
                interp1D_extremas(xq, x_cell, y_cell)
            end
            @cell py[ip, I] = yq
            @cell index[ip, I] = true
        end
        # fill empty memory locations
        for ip in (min_xcell+1):max_xcell
            @cell px[ip, I] = NaN
            @cell py[ip, I] = NaN
            @cell index[ip, I] = false
        end
    end
    return nothing
end

function isdistorded(x_cell, dx_ideal)
    for ip in eachindex(x_cell)[1:end-1]
        # current particle
        current_x = x_cell[ip]
        # if there is no particle in this memory location,
        # we do nothing
        isnan(current_x) && continue
        # next particle
        next_x = x_cell[ip+1]
        # check wether next memory location holds a particle;
        # if thats the case, find the next particle
        if isnan(next_x)
            next_index = findnext(!isnan, x_cell, ip + 1)
            isnothing(next_index) && break
            next_x = x_cell[next_index]
        end
        # check if the distance between particles is greater than 2*dx_ideal
        # if so, return true so that the cell is resampled
        dx = next_x - current_x
        if dx > 2 * dx_ideal
            return true
        end
    end
    return false
end
