# End-to-end differentiable blind tip reconstruction

![Deconvolution example](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/images/morphing.gif)

This repository contains Jupyter notebooks for the end-to-end differentiable blind tip reconstruction (BTR) used in Matsunaga et al. 

All notebooks are written in Julia programming language. You need to install julia before using the notebooks. 
Also, the notebooks depend on several packages. The packages can be installed as follows:

```julia
$ julia
julia> 
# enter the package mode by pressing ]
pkg> add IJulia Flux Plots Statistics BSON Revise HTTP ArgParse MLBase
pkg> add https://github.com/matsunagalab/MDToolbox.jl.git
# return to the REPL mode by pressing BACKSPACE or DELETE
julia> using IJulia
julia> exit()
```

## Descriptions on files

The files are organized as follows:

- [single_tip/](https://github.com/matsunagalab/differentiable_BTR/tree/main/single_tip) contains the twin experiment notebooks for single tip shape

  - [prepare_test_data.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/single_tip/prepare_test_data.ipynb) notebook for preparing pseudo AFM data used in the twin experiment. Recommended to start from this notebook. 

  - [blindtip_original.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/single_tip/blindtip_original.ipynb) notebook performs the original BTR under noise-free condition
 
  - [blindtip_opening.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/single_tip/blindtip_opening.ipynb) notebook performs the differentiable BTR under noise-free condition

  - [blindtip_original_randn.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/single_tip/blindtip_original_randn.ipynb) notebook performs the original BTR under noisy condition
 
  - [blindtip_opening_randn.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/single_tip/blindtip_opening_randn.ipynb) notebook performs the differentiable BTR under noisy condition

- [double_tip/](https://github.com/matsunagalab/differentiable_BTR/tree/main/double_tip) contains the twin experiment notebooks for double tip shape

  - [prepare_test_data.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/double_tip/prepare_test_data.ipynb) notebook for preparing pseudo AFM data used in the twin experiment. Recommended to start from this notebook. 

  - [blindtip_original_randn.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/double_tip/blindtip_original_randn.ipynb) notebook performs the original BTR under noisy condition
 
  - [blindtip_opening_randn.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/double_tip/blindtip_opening_randn.ipynb) notebook performs the differentiable BTR under noisy condition

- [myosin/](https://github.com/matsunagalab/differentiable_BTR/tree/main/myosin) contains the notebooks for the BTR of high-speed AFM data of Myosin V walking

  - [blindtip_myosin_original_863-892.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/myosin/blindtip_myosin_original_863-892.ipynb) notebook performs the original BTR
 
  - [blindtip_myosin_opening_863-892.ipynb](https://github.com/matsunagalab/differentiable_BTR/blob/main/myosin/blindtip_myosin_opening_863-892.ipynb) notebook performs the differentiable BTR
  
## Standalone scripts

Standalone scripts written in Julia are available in `script/` directory for the end-to-end differentiable blind tip reconstruction, cross validation, erosion, dilation, and RANSAC (for correcting tilt in AFM images). All the scripts read and write CSV-formatted AFM images files. For each usage, please see the ouptus of `--help` option. 

A typical work flow using the scripts would be follows:

```bash
$ cd script/
$ julia dblindtip.jl --help # check options

# 1. perform cross validaton and select an appropriate lambda value
$ julia dblindtip_cv.jl --output cv.png --lambda_start 1.0e-5 --lambda_stop 0.01 --lambda_length 5 data/
$ ls -l cv.png # This plot shows the one standard error range. 

# 2. perform the end-to-end differentiable blind tip reconstruction
$ julia dblindtip.jl --output tip.csv --lambda 1.0e-5 data/
$ ls -l tip.csv # This csv file contains the reconstructed tip shape information

# 3. perform erosion (deconvolution) with the reconstructed tip shape
$ julia erosion.jl --tip tip.csv data/
$ ls data/*_erosion # These CSV files contain the eroded (deconvoluted) images
```

## Acknowledgement and Citation

The original BTR in the notebooks is based on the algorithm and code provided by Villarrubia, J. Res. Natl. Inst. Stand. Technol. 102, 425 (1997). If you use the original BTR of the notebooks, please cite this paper. 

The original BTR with an improved regularization scheme is based on F. Tian, X. Qian, and J. S. Villarrubia, Ultramicroscopy 109, 44 (2008), and G. Jóźwiak, A. Henrykowski, A. Masalska, and T. Gotszalk, Ultramicroscopy 118, 1 (2012).

## License

This repository is licensed under the under the terms of GNU General Public License v3.0. 

Quaternion data contained in `quaternion/` directory were taken from the repository of the BioEM program written by Cossio et al. https://github.com/bio-phys/BioEM. These are separately licensed under the terms of the GNU General Public License. Please check the license file `quaternion/LICENSE`. 
 
## Contact

Yasuhiro Matsunaga

ymatsunaga@mail.saitama-u.ac.jp

