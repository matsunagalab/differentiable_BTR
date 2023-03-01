# End-to-end differentiable blind tip reconstruction

![Deconvolution example](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/images/morphing.gif)

This repository contains Jupyter notebooks for the end-to-end differentiable blind tip reconstruction (BTR) proposed in [Matsunaga et al (2023)](https://doi.org/10.1038/s41598-022-27057-2). 

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

The files are organized as follows. Note that all scripts assume Angstrom as the unit. 

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

Standalone scripts written in Julia are available in `script/` directory for the end-to-end differentiable blind tip reconstruction `dblindtip.jl`, cross validation `dblindtip_cv.jl`, erosion `erosion.jl`, dilation `dilation.jl`, visualization of CSV files (`csv2png.jl` and `csv2gif.jl`), visualization of tip (`tip2png.jl`), and RANSAC `ransac.jl` (for correcting tilt in AFM images). All the scripts read and write CSV-formatted AFM images files. For each usage, please see the ouptus of `--help` option. Note that all scripts assume nm as the unit. 

A typical work flow using the scripts would be follows. You can try them using test data in `script/data/` (a double-tip case).

### 0. check the usages and options of scripts
```bash
$ cd script/
$ julia dblindtip.jl --help # check usage and options
```

### 1. visualize AFM data
```bash
# PNG of each CSV file
$ julia csv2png.jl data/
# GIF of all CSV files
$ julia csv2gif.jl --output original.gif data/
```

![Original AFM](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/script/original.gif)

### 2. perform cross validaton (LOOCV) and select an appropriate lambda value
```bash
# Perform LOOCV and choose an lambda value according to the one standard error rule
$ julia dblindtip_cv.jl --output cv.png --lambda_start 1.0e-5 --lambda_stop 0.01 --lambda_length 4 data/
```

Following the one standard error rule, it is recommended to select the largest lambda whose mean (indicate by the solid line in the figure below) falls within or around the one standard deviation of the minimum (indicated by the shaded area). In this case, lambda = 1.0e-4 would be recommended. 

![Cross validation](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/script/cv.png)

### 3. perform the end-to-end differentiable blind tip reconstruction
```bash
# perform the end-to-end differentiable blind tip reconstruction
$ julia dblindtip.jl --output tip.csv --lambda 1.0e-4 data/
# visualize the reconstructed tip
$ julia tip2png.jl tip.csv
```

![Reconstructed tip](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/script/tip.png)

### 4. perform erosion (deconvolution) with the reconstructed tip shape
```bash
# perform erosion (deconvolution)
$ julia erosion.jl --tip tip.csv data/
# visualize eroded (deconvoluted) molecular surfaces
$ julia csv2png.jl --ext csv_erosion data/
$ julia csv2gif.jl --output erosion.gif --ext csv_erosion data/
```

![Original AFM](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/script/erosion.gif)

## Citation and Acknowledgement

### End-to-end differentiable blind tip reconstruction

Citation information on [the end-to-end differentiable blind tip reconstruction](https://doi.org/10.1038/s41598-022-27057-2):

```
Y. Matsunaga, S. Fuchigami, T. Ogane, and S. Takada. 
End-to-end differentiable blind tip reconstruction for noisy atomic force microscopy images. 
Sci. Rep. 13, 129 (2023). 
https://doi.org/10.1038/s41598-022-27057-2
```

### Original blind tip reconstruction

The original BTR in the notebooks is based on the algorithm and code provided by Villarrubia, J. Res. Natl. Inst. Stand. Technol. 102, 425 (1997). If you use the original BTR of the notebooks, please cite this paper. 

```
J. S. Villarrubia, 
Algorithms for Scanned Probe Microscope Image Simulation, Surface Reconstruction, and Tip Estimation, 
J. Res. Natl. Inst. Stand. Technol. 102, 425 (1997).
```

### Regularized blind tip reconstruction

The original BTR with an improved regularization scheme is based on F. Tian, X. Qian, and J. S. Villarrubia, Ultramicroscopy 109, 44 (2008), and G. Jóźwiak, A. Henrykowski, A. Masalska, and T. Gotszalk, Ultramicroscopy 118, 1 (2012).

```
F. Tian, X. Qian, and J. S. Villarrubia, 
Blind Estimation of General Tip Shape in AFM Imaging, 
Ultramicroscopy 109, 44 (2008).
```

```
G. Jóźwiak, A. Henrykowski, A. Masalska, and T. Gotszalk, 
Regularization Mechanism in Blind Tip Reconstruction Procedure, 
Ultramicroscopy 118, 1 (2012).

```

## License

This repository is licensed under the under the terms of GNU General Public License v3.0. 

Quaternion data contained in `quaternion/` directory were taken from the repository of the BioEM program written by Cossio et al. https://github.com/bio-phys/BioEM. These are separately licensed under the terms of the GNU General Public License. Please check the license file `quaternion/LICENSE`. 
 
## Contact

If you have any questions or troubles, feel free to create github issues, or send email to us. 

Yasuhiro Matsunaga

ymatsunaga@mail.saitama-u.ac.jp

