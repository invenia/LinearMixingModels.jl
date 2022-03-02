# LinearMixingModels

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/LinearMixingModels.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/LinearMixingModels.jl/dev)
[![Build Status](https://github.com/invenia/LinearMixingModels.jl/workflows/CI/badge.svg)](https://github.com/invenia/LinearMixingModels.jl/actions)
[![Coverage](https://codecov.io/gh/invenia/LinearMixingModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/LinearMixingModels.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

A package for implementing [Instantaneous Linear Mixing Models](https://arxiv.org/pdf/1911.06287.pdf) (ILMMs) and Orthogonal Instantaneous Linear Mixing Models (OILMMs) using the [AbstractGPs](https://juliagaussianprocesses.github.io/AbstractGPs.jl/stable/) interface.

## Installation

```julia
julia> Pkg.add("LinearMixingModels")
```

## Simple usage example

```julia
julia> H = Orthogonal(U, Diagonal(S))

julia> latent_gp = independent_mogp(GP(Matern52Kernel()), GP(Matern32Kernel())]);

julia> oilmm = ILMM(latent_gp, H);

julia> oilmmx = oilmm(x_train, 1e-6);

julia> y_train = rand(oilmmx);

julia> p_oilmmx = posterior(oilmmx, y_train);

julia> po = p_oilmmx(x_test, 1e-6);

julia> marg_po = marginals(po)

julia> rand_po = rand(rng, po)
```
