# Differentiable blind tip reconstruction

This repository contains Jupyter notebooks for differentiable blind tip reconstruction (BTR) used in Matsunaga et al. (2022). 

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

## Descriptions on files

The files are organied as the following:

- `single_tip/` contains the twin experiment notebooks for single tip shape

  - `blindtip_original.ipynb` notebook performs the original BTR under noise-free condition
 
  - `blindtip_opening.ipynb` notebook performs the differentiable BTR under noise-free condition

  - `blindtip_original_randn.ipynb` notebook performs the original BTR under noisy condition
 
  - `blindtip_opening_randn.ipynb` notebook performs the differentiable BTR under noisy condition

- `double_tip/` contains the twin experiment notebooks for double tip shape

  - `blindtip_original_randn.ipynb` notebook performs the original BTR under noisy condition
 
  - `blindtip_opening_randn.ipynb` notebook performs the differentiable BTR under noisy condition

- `myosin/` contains the notebooks for the BTR of high-speed AFM data of Myosin V walking

  - `blindtip_myosin_original_863-892.ipynb` notebook performs the original BTR
 
  - `blindtip_myosin_original_863-892.ipynb` notebook performs the differentiable BTR
 
## Contact

Yasuhiro Matsunaga

ymatsunaga@mail.saitama-u.ac.jp


