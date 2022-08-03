mutable struct Choice{T}
    name::String
    possibleValues::AbstractVector{T, 1}
end