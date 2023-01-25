module SignedDistanceFunctions

# Geometry base types.
export CentredGeometry, Geometry

# Simple geometries.
export Sphere

# Functional API
export scale, shift, signed_distance

using LinearAlgebra

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
* `x::NTuple{AbstractFloat,D}`: The position in space.
"""
function signed_distance end

############################
# Concrete implementation. #
############################

"""
    Sphere{D}

The unit sphere in `D` dimensions.
"""
struct Sphere{D} <: CentredGeometry{D} end

signed_distance(::Sphere{D}, x::NTuple{D,AbstractFloat}) where {D} = norm(x) - 1.0

# TODO we need to ensure that we don't nest these geometry objects too deeply, since
#   otherwise we will suffer greatly when compiling this code.

abstract type Scale{D} <: Geometry{D} end

struct IsotropicScale{D,G<:Geometry{D}} <: Scale{D}
    parent::G
    factor::Float64
end

struct AnisotropicScale{D,G<:Geometry{D}} <: Scale{D}
    parent::G
    factor::NTuple{D,Float64}
end

"""
    scale(g::Geometry, factor::Float64)
    scale(g::Geometry, factor::NTuple)

Scale the given geometry by `factor`.

If the factor is a scalar, this will be a
"""
function scale(g::Geometry{D}, factor::Float64) where {D}
    return IsotropicScale{D,typeof(g)}(g, factor)
end

function scale(g::Geometry{D}, factor::NTuple{D,Float64}) where {D}
    return AnisotropicScale{D,typeof(g)}(g, factor)
end

function signed_distance(scale::Scale{D}, x::NTuple{D,AbstractFloat}) where {D}
    return signed_distance(scale.parent, x ./ scale.factor)
end

# TODO optimise scaling a Scale object

struct Shift{D,G<:Geometry{D}} <: Geometry{D}
    parent::G
    delta::NTuple{D,Float64}
end

shift(g::Geometry{D}, delta::NTuple{D,Float64}) where {D} = Shift{D,typeof(g)}(g, delta)

function signed_distance(shift::Shift{D}, x::NTuple{D,AbstractFloat}) where {D}
    return signed_distance(shift.parent, x .- shift.delta)
end

# TODO optimise shifting a shift object

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
    return minimum(g.components) do geometry
        signed_distance(geometry, x)
    end
end

end
