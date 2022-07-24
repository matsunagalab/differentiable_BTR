# differentiable blind tip reconstruction

This repository contains Jupyter notebooks for differentiable blind tip reconstruction used in Matsunaga et al. (2022). 

All notebooks are written in Julia programming language. You need to install julia before using the notebooks. 
Also, the notebooks depends on several packages. The package can be installed by the following commands:

```julia
$ julia
julia> 
# enter the package mode by pressing ]
pkg> add IJulia, Flux, Plots, Statistics, BSON, Revise, HTTP
pkg> add https://github.com/matsunagalab/MDToolbox.jl.git
# return to the REPL mode by pressing BACKSPACE or DELETE
julia> using IJulia
julia> exit()
```

## Contact

- Yasuhiro Matsunaga
- ymatsunaga@mail.saitama-u.ac.jp

