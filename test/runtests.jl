using AbstractGPs
using Distributions
using Documenter
using FillArrays
using KernelFunctions
using LinearAlgebra
using LinearMixingModels
using Random
using Test
using Zygote

using AbstractGPs: AbstractGP, FiniteGP
using AbstractGPs.TestUtils:
    test_finitegp_primary_public_interface,
    test_finitegp_primary_and_secondary_public_interface,
    test_internal_abstractgps_interface
using KernelFunctions: MOInputIsotopicByOutputs
using LinearMixingModels: unpack, noise_var, get_latent_gp, reshape_y

function _is_approx(x::AbstractVector{<:Normal}, y::AbstractVector{<:Normal})
    return (map(mean, x) ≈ map(mean, y)) && (map(std, x) ≈ map(std, y))
end

@testset "LinearMixingModels.jl" begin

    @testset "independent_mogp" begin
        include("independent_mogp.jl")
    end
    @info "Ran independent_mogp tests."

    # @testset "orthogonal_matrix" begin
    #     include("orthogonal_matrix.jl")
    # end
    # @info "Ran orthogonal_matrix tests."

    @testset "ilmm" begin
        include("ilmm.jl")
    end
    @info "Ran ilmm tests."

    @testset "oilmm" begin
        include("oilmm.jl")
    end
    @info "Ran oilmm tests."

    # @testset "doctests" begin
    #     DocMeta.setdocmeta!(
    #         LinearMixingModels,
    #         :DocTestSetup,
    #         quote
    #             using AbstractGPs
    #             using KernelFunctions
    #             using LinearMixingModels
    #             using Random
    #             using LinearAlgebra
    #             using FillArrays
    #         end;
    #         recursive=true,
    #     )
    #     doctest(
    #         LinearMixingModels;
    #         doctestfilters=[
    #             r"{([a-zA-Z0-9]+,\s?)+[a-zA-Z0-9]+}",
    #             r"(Array{[a-zA-Z0-9]+,\s?1}|\s?Vector{[a-zA-Z0-9]+})",
    #             r"(Array{[a-zA-Z0-9]+,\s?2}|\s?Matrix{[a-zA-Z0-9]+})",
    #         ],
    #     )
    # end
    # @info "Ran doctests."
end
