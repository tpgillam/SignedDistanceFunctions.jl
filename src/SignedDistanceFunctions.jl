module SignedDistanceFunctions

# Geometry base types.
export CentredGeometry, Geometry

# Simple geometries.
export Cube, Sphere

# Functional API
export scale, shift, signed_distance

using LinearAlgebra

# TODO Switch to using SVector rather than bare Tuples, since it is slightly closer to what
#   we mean semantically. It is also more likely to have optimised & inlining versions of
#   base & linear algebra routines.

# TODO Generalise for arbitrary float types

"""
    Geometry{D}

Abstract type representing a `D`-dimensional geometry.
"""
abstract type Geometry{D} end

# TODO do we need this concept?
"""
    CentredGeometry{D} <: Geometry{D}

Geometry that is centred on the origin.
"""
abstract type CentredGeometry{D} <: Geometry{D} end

"""
    signed_distance(geometry, x)

Get the signed distance from position `x` to `geometry`.

# Args
* `geometry::Geometry{D}`: An object representing the geometry.
* `x::NTuple{Real,D}`: The position in space.
"""
function signed_distance end

############################
# Concrete implementation. #
############################

"""
    Cube{D}

The unit cube centred on the origin in `D` dimensions.
"""
struct Cube{D} <: CentredGeometry{D} end

function signed_distance(::Cube{D}, x::NTuple{D,Real}) where {D}
    q = @. abs(x) - 0.5
    # The first component is >= 0 iff x is outside the cube.
    # The second component is zero outside the cube, but is negative inside the cube.
    return norm(max.(q, 0.0)) + min(maximum(q), 0.0)
end

"""
    Sphere{D}

The unit sphere centred on the origin in `D` dimensions.
"""
struct Sphere{D} <: CentredGeometry{D} end

signed_distance(::Sphere{D}, x::NTuple{D,Real}) where {D} = norm(x) - 1.0

# TODO we need to ensure that we don't nest these geometry objects too deeply, since
#   otherwise we will suffer greatly when compiling this code.

struct Scale{D,G<:Geometry{D}} <: Geometry{D}
    parent::G
    factor::Float64
end

"""
    scale(g::Geometry, factor::Float64)

Scale the given geometry by `factor` in all dimensions.
Note that we cannot in general scale an SDF by different factors in different dimensions.
"""
scale(g::Geometry{D}, factor::Float64) where {D} = Scale{D,typeof(g)}(g, factor)
scale(g::Scale{D}, factor::Float64) where {D} = typeof(g)(g.parent, g.factor * factor)

function signed_distance(scale::Scale{D}, x::NTuple{D,Real}) where {D}
    return signed_distance(scale.parent, x ./ scale.factor)
end

struct Shift{D,G<:Geometry{D}} <: Geometry{D}
    parent::G
    delta::NTuple{D,Float64}
end

shift(g::Geometry{D}, delta::NTuple{D,Float64}) where {D} = Shift{D,typeof(g)}(g, delta)
function shift(g::Shift{D}, delta::NTuple{D,Float64}) where {D}
    return typeof(g)(g.parent, g.delta + delta)
end

function signed_distance(shift::Shift{D}, x::NTuple{D,Real}) where {D}
    return signed_distance(shift.parent, x .- shift.delta)
end

struct UnionGeometry{D} <: Geometry{D}
    components::Vector{<:Geometry{D}}
end

"""
    union(g::Geometry, rest...)

Create a geometry which is the union of all given geometries.
"""
Base.union(g::Geometry) = g
Base.union(g::Geometry{D}, rest::Geometry{D}...) where {D} = UnionGeometry{D}([g, rest...])

function signed_distance(g::UnionGeometry{D}, x::NTuple{D,Float64}) where {D}
    min = minimum(g.components) do geometry
        signed_distance(geometry, x)
    end
    # Interiors are not guaranteed to be correct if any shapes overlap anywhere. It is not
    #   sufficient to only check for overlaps at the point `x`!
    #   TODO: we could potentially determine some cases of unions that are non-overlapping,
    #       when it would be correct to provide the interior.
    return min < 0 ? missing : min
end

struct IntersectionGeometry{D} <: Geometry{D}
    components::Vector{<:Geometry{D}}
end

"""
    intersect(g::Geometry, rest...)

Create a geometry which is the intersection of all given geometries.
"""
Base.intersect(g::Geometry) = g
function Base.intersect(g::Geometry{D}, rest::Geometry{D}...) where {D}
    return IntersectionGeometry{D}([g, rest...])
end

function signed_distance(g::IntersectionGeometry{D}, x::NTuple{D,Float64}) where {D}
    return maximum(g.components) do geometry
        signed_distance(geometry, x)
    end
end

end
