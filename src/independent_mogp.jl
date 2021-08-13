"""
    IndependentMOGP(fs)

A multi-output GP with independent outputs where output `i` is modelled by the
single-output GP fs[i].

# Arguments:
- fs: a vector of `p` single-output GPs where `p` is the dimension of the output.
"""
struct IndependentMOGP{Tg<:Vector{<:AbstractGPs.AbstractGP}} <: AbstractGPs.AbstractGP
    fs::Tg
end

"""
    independent_mogp(fs)

Returns an IndependentMOGP given a list of single output GPs `fs`.

```jldoctest
julia> independent_mogp([GP(SEKernel())]) == IndependentMOGP([GP(SEKernel())])
true
```
"""
function independent_mogp(fs::Vector{<:AbstractGPs.AbstractGP})
    return IndependentMOGP(fs)
end

"""
A constant to represent all isotopic input types.
"""
const isotopic_inputs = Union{
    MOInputIsotopicByFeatures, MOInputIsotopicByOutputs
}

"""
    finite_gps(fx)

Returns a list of of the finite GPs for all latent processes, given a finite
IndependentMOGP and *isotopic inputs*.
"""
function finite_gps(fx::FiniteGP{<:IndependentMOGP, <:isotopic_inputs})
    return [f(fx.x.x, fx.Σy[1:length(fx.x.x),1:length(fx.x.x)]) for f in fx.f.fs]
    # return [f(fx.x.x, fx.Σy) for f in fx.f.fs]
end

"""
    finite_gps(fx)

Returns a list of of the finite GPs for all latent processes, given a finite
IndependentMOGP, *isotopic inputs* and .
"""
# function finite_gps(fx::FiniteGP{<:IndependentMOGP,<:isotopic_inputs}, x::AbstractVector)
#     return [f(x, fx.Σy[1:length(fx.x.x),1:length(fx.x.x)]) for f in fx.f.fs]
# end

# Implement AbstractGPs API

# See AbstractGPs.jl API docs.
function AbstractGPs.marginals(ft::FiniteGP{<:IndependentMOGP})
    finiteGPs = finite_gps(ft)
    return reduce(vcat, map(AbstractGPs.marginals, finiteGPs))
end

# See AbstractGPs.jl API docs.
function AbstractGPs.mean_and_var(ft::FiniteGP{<:IndependentMOGP})
    ms = AbstractGPs.marginals(ft)
    return reshape(map(mean, ms), length(ft.x)), map(var, ms)
end

# See AbstractGPs.jl API docs.
function AbstractGPs.mean_and_cov(ft::FiniteGP{<:IndependentMOGP})
    return mean(ft), cov(ft)
end

# See AbstractGPs.jl API docs.
AbstractGPs.var(ft::FiniteGP{<:IndependentMOGP}) = mean_and_var(ft)[2]

# See AbstractGPs.jl API docs.
function AbstractGPs.cov(
    f::IndependentMOGP,
    x::AbstractVector,
    y::AbstractVector
)
    n = length(x)
    m = length(y)
    Σ = zeros(n, m)
    for i in 1:n
        for j in i:m
            if x[i][2]==y[j][2]
                p = x[i][2]
                Σ[i,j] = f.fs[p].kernel(x[i][1], y[j][1])
                Σ[j,i] = Σ[i,j]
            end
        end
    end
    return Σ
end

AbstractGPs.cov(ft::FiniteGP{<:IndependentMOGP}) = cov(ft.f, ft.x, ft.x)

function Statistics.cov(ft::FiniteGP{<:IndependentMOGP}, gt::FiniteGP{<:IndependentMOGP})
    return cov(ft.f, ft.x, gt.x)
end

# See AbstractGPs.jl API docs.
AbstractGPs.mean(ft::FiniteGP{<:IndependentMOGP}) = mean_and_var(ft)[1]

# See AbstractGPs.jl API docs.
function AbstractGPs.logpdf(ft::FiniteGP{<:IndependentMOGP}, y::AbstractVector)
    finiteGPs = finite_gps(ft)
    ys = collect(eachcol(reshape(y, (length(ft.x.x), :))))
    return sum([logpdf(fx, y_i) for (fx, y_i) in zip(finiteGPs, ys)])
end

# See AbstractGPs.jl API docs.
function AbstractGPs.rand(rng::AbstractRNG, ft::FiniteGP{<:IndependentMOGP})
    finiteGPs = finite_gps(ft)
    return vcat(map(fx -> rand(rng, fx), finiteGPs)...)
end

AbstractGPs.rand(ft::FiniteGP{<:IndependentMOGP}) = rand(Random.GLOBAL_RNG, ft)

function AbstractGPs.rand(rng::AbstractRNG, ft::FiniteGP{<:IndependentMOGP}, N::Int)
    return reduce(hcat, [rand(rng, ft) for _ in 1:N])
end

AbstractGPs.rand(ft::FiniteGP{<:IndependentMOGP}, N::Int) = rand(Random.GLOBAL_RNG, ft, N)

"""
Posterior implementation for isotopic inputs, given diagonal Σy (OILMM).
See AbstractGPs.jl API docs.
"""
function AbstractGPs.posterior(
    ft::FiniteGP{<:IndependentMOGP},
    y::AbstractVector{<:Real}
)
    finiteGPs = finite_gps(ft)
    ys = collect(eachcol(reshape(y, (length(ft.x.x),:))))
    ind_posts = [AbstractGPs.posterior(fx, y_i) for (fx, y_i) in zip(finiteGPs, ys)]
    return IndependentMOGP(ind_posts)
end
