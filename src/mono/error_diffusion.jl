function error_diffusion(
    img::AbstractMatrix{<:Gray}, stencil::OffsetMatrix; to_linear=false
)::BitMatrix
    # Optionally cast to linear colorspace
    _img = copy(img)
    to_linear && srgb2linear!(_img)

    # Change from normalized intensities to Float as error will get added!
    _img = Float32.(_img)

    h, w = size(_img)
    dither = BitArray(undef, h, w) # initialized to zero

    # Get OffsetMatrix indices
    drs, dcs = indices(stencil)

    for r in 1:h
        for c in 1:w
            px = _img[r, c]

            # Round to closest color
            px >= 0.5 ? (rnd = 1) : (rnd = 0)

            # Apply pixel to dither
            dither[r, c] = rnd

            # Diffuse "error" to neighborhood in stencil
            err = px - rnd
            for dr in drs
                for dc in dcs
                    if (r + dr > 0) && (r + dr <= h) && (c + dc > 0) && (c + dc <= w)
                        _img[r + dr, c + dc] += err * stencil[dr, dc]
                    end
                end
            end
        end
    end

    return dither
end

"""
Get indices from OffsetMatrix
"""
function indices(om::OffsetMatrix)
    rows, cols = size(om)
    row_range = (1:rows) .+ om.offsets[1]
    col_range = (1:cols) .+ om.offsets[2]
    return row_range, col_range
end

simple_error_diffusion(img; kwargs...) = error_diffusion(img, SIMPLE_STENCIL; kwargs...)
SIMPLE_STENCIL = OffsetArray([0 1; 1 0]//2, 0:1, 0:1)

floyd_steinberg_diffusion(img; kwargs...) = error_diffusion(img, FS_STENCIL; kwargs...)
FS_STENCIL = OffsetArray([0 0 7; 3 5 1]//16, 0:1, -1:1)

jarvis_judice_diffusion(img; kwargs...) = error_diffusion(img, JJ_STENCIL; kwargs...)
JJ_STENCIL = OffsetArray([0 0 0 7 5; 3 5 7 5 3; 1 3 5 3 1]//48, 0:2, -2:2)

stucki_diffusion(img; kwargs...) = error_diffusion(img, STUCKI_STENCIL; kwargs...)
STUCKI_STENCIL = OffsetArray([0 0 0 8 4; 2 4 8 4 2; 1 2 4 2 1]//42, 0:2, -2:2)

burkes_diffusion(img; kwargs...) = error_diffusion(img, BURKES_STENCIL; kwargs...)
BURKES_STENCIL = OffsetArray([0 0 0 8 4; 2 4 8 4 2]//32, 0:1, -2:2)

sierra_diffusion(img; kwargs...) = error_diffusion(img, SIERRA_STENCIL; kwargs...)
SIERRA_STENCIL = OffsetArray([0 0 0 5 3; 2 4 5 4 2; 0 2 3 2 0]//32, 0:2, -2:2)

function two_row_sierra_diffusion(img; kwargs...)
    return error_diffusion(img, TWO_ROW_SIERRA_STENCIL; kwargs...)
end
TWO_ROW_SIERRA_STENCIL = OffsetArray([0 0 0 4 3; 1 2 3 2 1]//16, 0:1, -2:2)

sierra_lite_diffusion(img; kwargs...) = error_diffusion(img, SIERRA_LITE_STENCIL; kwargs...)
SIERRA_LITE_STENCIL = OffsetArray([0 0 2; 1 1 0]//4, 0:1, -1:1)

atkinson_diffusion(img; kwargs...) = error_diffusion(img, ATKINSON_STENCIL; kwargs...)
ATKINSON_STENCIL = OffsetArray([0 0 1 1; 1 1 1 0; 0 1 0 0]//8, 0:2, -1:2)
