"""
    IndependentMOGP(fs)

A multi-output GP with independent outputs where output `i` is modelled by the
single-output GP fs[i].

# Arguments:
- fs: a vector of `p` single-output GPs where `p` is the dimension of the output.
"""
struct IndependentMOGP{Tfs<:Vector{<:AbstractGP}} <: AbstractGP
    fs::Tfs
end

"""
    independent_mogp(fs)

Returns an IndependentMOGP given a list of single output GPs `fs`.

```jldoctest
julia> ind_mogp1 = independent_mogp([GP(KernelFunctions.SEKernel())]);

julia> ind_mogp2 = IndependentMOGP([GP(KernelFunctions.SEKernel())]);

julia> typeof(ind_mogp1) == typeof(ind_mogp2)
true

julia> ind_mogp1.fs == ind_mogp2.fs
true
```
"""
independent_mogp(fs::Vector{<:AbstractGP}) = IndependentMOGP(fs)

"""
    finite_gps(fx)

Returns a list of of the finite GPs for all latent processes, given a finite
IndependentMOGP and *isotopic inputs*.
"""
function finite_gps(fx::FiniteGP{<:IndependentMOGP, <:MOInputIsotopicByOutputs}, σ²::Real)
    return [f(fx.x.x, σ²) for f in fx.f.fs]
end

const IsotropicByOutputsFiniteIndependentMOGP = FiniteGP{
    <:IndependentMOGP,<:MOInputIsotopicByOutputs,<:Diagonal{<:Real,<:Fill}
}

# Optimisations for MOInputIsotopicByOutputs.

# See AbstractGPs.jl API docs.
function AbstractGPs.mean(f::IndependentMOGP, x::MOInputIsotopicByOutputs)
    return reduce(vcat, map(f -> mean(f, x.x), f.fs))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.var(f::IndependentMOGP, x::MOInputIsotopicByOutputs)
    return reduce(vcat, map(f -> var(f, x.x), f.fs))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.cov(f::IndependentMOGP, x::MOInputIsotopicByOutputs)
    Cs = map(f -> cov(f, x.x), f.fs)
    return Matrix(BlockDiagonal(Cs))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.cov(
    f::IndependentMOGP, x::MOInputIsotopicByOutputs, y::MOInputIsotopicByOutputs
)
    Cs = map(f -> cov(f, x.x, y.x), f.fs)
    return Matrix(BlockDiagonal(Cs))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.logpdf(
    ft::IsotropicByOutputsFiniteIndependentMOGP, y::AbstractVector{<:Real}
)
    finiteGPs = finite_gps(ft, ft.Σy[1])
    ys = collect(eachcol(reshape(y, (length(ft.x.x), :))))
    return sum(map(logpdf, finiteGPs, ys))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.rand(rng::AbstractRNG, ft::IsotropicByOutputsFiniteIndependentMOGP)
    finiteGPs = finite_gps(ft, ft.Σy[1])
    return reduce(vcat, map(fx -> rand(rng, fx), finiteGPs))
end

# See AbstractGPs.jl API docs.
AbstractGPs.rand(ft::FiniteGP{<:IndependentMOGP}) = rand(Random.GLOBAL_RNG, ft)

# See AbstractGPs.jl API docs.
function AbstractGPs.rand(
    rng::AbstractRNG, ft::IsotropicByOutputsFiniteIndependentMOGP, N::Int
)
    return reduce(hcat, [rand(rng, ft) for _ in 1:N])
end

# See AbstractGPs.jl API docs.
AbstractGPs.rand(ft::FiniteGP{<:IndependentMOGP}, N::Int) = rand(Random.GLOBAL_RNG, ft, N)

# See AbstractGPs.jl API docs.
function Distributions._rand!(
    rng::AbstractRNG,
    fx::FiniteGP{<:IndependentMOGP},
    y::AbstractVecOrMat{<:Real}
)
    N = size(y, 2)
    if N == 1
        y .= AbstractGPs.rand(rng, fx)
    else
        y .= AbstractGPs.rand(rng, fx, N)
    end
end

"""
Posterior implementation for isotopic inputs, given diagonal Σy (OILMM).
See AbstractGPs.jl API docs.
"""
function AbstractGPs.posterior(
    ft::IsotropicByOutputsFiniteIndependentMOGP, y::AbstractVector{<:Real}
)
    finiteGPs = finite_gps(ft, ft.Σy[1])
    ys = collect(eachcol(reshape(y, (length(ft.x.x), :))))
    ind_posts = [AbstractGPs.posterior(fx, y_i) for (fx, y_i) in zip(finiteGPs, ys)]
    return independent_mogp(ind_posts)
end

# AbstractGPs APIs implementations for MOInputIsotopicByFeatures.

const IsotropicByFeaturesFiniteIndependentMOGP = FiniteGP{
    <:IndependentMOGP,<:MOInputIsotopicByFeatures,<:Diagonal{<:Real,<:Fill}
}

# Indices which, when applied to a vector ordered by features, will order it by outputs.
function indices_which_reorder_outputs_to_features(
    x::Union{MOInputIsotopicByOutputs,MOInputIsotopicByFeatures}
)
    return collect(vec(reshape(1:length(x), length(x.x), x.out_dim)'))
end

function indices_which_reorder_features_to_outputs(
    x::Union{MOInputIsotopicByOutputs,MOInputIsotopicByFeatures}
)
    return collect(vec(reshape(1:length(x), x.out_dim, length(x.x))'))
end

reorder_by_outputs(x::MOInputIsotopicByFeatures) = MOInputIsotopicByOutputs(x.x, x.out_dim)

function reorder_by_outputs(Σy::Diagonal{<:Real}, x::MOInputIsotopicByFeatures)
    return Diagonal(Σy.diag[indices_which_reorder_features_to_outputs(x)])
end

reorder_by_outputs(Σy::Diagonal{<:Real,<:Fill}, x::MOInputIsotopicByFeatures) = Σy

function reorder_by_outputs(
    fx::FiniteGP{<:IndependentMOGP,<:MOInputIsotopicByFeatures,<:Diagonal{<:Real}}
)
    return FiniteGP(fx.f, reorder_by_outputs(fx.x), reorder_by_outputs(fx.Σy, fx.x))
end

@non_differentiable indices_which_reorder_outputs_to_features(::Any)
@non_differentiable indices_which_reorder_features_to_outputs(::Any)
@non_differentiable reorder_by_outputs(::Any)

function finite_gps(fx::FiniteGP{<:IndependentMOGP,<:MOInputIsotopicByFeatures}, σ²::Real)
    return [f(fx.x.x, σ²) for f in fx.f.fs]
end

function AbstractGPs.mean(f::IndependentMOGP, x::MOInputIsotopicByFeatures)
    x_by_outputs = reorder_by_outputs(x)
    mean_by_outputs = mean(f, x_by_outputs)
    return mean_by_outputs[indices_which_reorder_outputs_to_features(x_by_outputs)]
end

function AbstractGPs.var(f::IndependentMOGP, x::MOInputIsotopicByFeatures)
    x_by_outputs = reorder_by_outputs(x)
    var_by_outputs = var(f, x_by_outputs)
    return var_by_outputs[indices_which_reorder_outputs_to_features(x_by_outputs)]
end

function AbstractGPs.cov(f::IndependentMOGP, x::MOInputIsotopicByFeatures)
    x_by_outputs = reorder_by_outputs(x)
    C_by_outputs = cov(f, x_by_outputs)
    idx = indices_which_reorder_outputs_to_features(x_by_outputs)
    return C_by_outputs[idx, idx]
end

function AbstractGPs.cov(
    f::IndependentMOGP, x::MOInputIsotopicByFeatures, y::MOInputIsotopicByFeatures
)
    x_by_outputs = reorder_by_outputs(x)
    y_by_outputs = reorder_by_outputs(y)
    C_by_outputs = cov(f, x_by_outputs, y_by_outputs)
    idx_x = indices_which_reorder_outputs_to_features(x_by_outputs)
    idx_y = indices_which_reorder_outputs_to_features(y_by_outputs)
    return C_by_outputs[idx_x, idx_y]
end

function AbstractGPs.cov(
    f::IndependentMOGP, x::MOInputIsotopicByFeatures, y::MOInputIsotopicByOutputs
)
    x_by_outputs = reorder_by_outputs(x)
    C_by_outputs = cov(f, x_by_outputs, y)
    idx_x = indices_which_reorder_outputs_to_features(x_by_outputs)
    return C_by_outputs[idx_x, :]
end

function AbstractGPs.cov(
    f::IndependentMOGP, x::MOInputIsotopicByOutputs, y::MOInputIsotopicByFeatures
)
    y_by_outputs = reorder_by_outputs(y)
    C_by_outputs = cov(f, x, y_by_outputs)
    idx_y = indices_which_reorder_outputs_to_features(y_by_outputs)
    return C_by_outputs[:, idx_y]
end

function AbstractGPs.rand(rng::AbstractRNG, ft::IsotropicByFeaturesFiniteIndependentMOGP)
    finiteGPs = finite_gps(ft, ft.Σy[1])
    return vec(reduce(hcat, map(fx -> rand(rng, fx), finiteGPs))')
end

function AbstractGPs.logpdf(
    ft::FiniteGP{<:IndependentMOGP,<:MOInputIsotopicByFeatures,<:Diagonal{<:Real}},
    y::AbstractVector{<:Real},
)
    return logpdf(
        reorder_by_outputs(ft), y[indices_which_reorder_features_to_outputs(ft.x)]
    )
end
