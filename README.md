# End-to-end differentiable blind tip reconstruction

![Deconvolution example](https://raw.githubusercontent.com/matsunagalab/differentiable_BTR/main/images/morphing3.gif)

This repository contains Jupyter notebooks for the end-to-end differentiable blind tip reconstruction (BTR) used in Matsunaga et al. (2022). 

All notebooks are written in Julia programming language. You need to install julia before using the notebooks. 
Also, the notebooks depend on several packages. The packages can be installed as follows:

```julia
$ julia
julia> 
# enter the package mode by pressing ]
pkg> add IJulia Flux Plots Statistics BSON Revise HTTP ArgParse
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
  
## Standalone scripts and compiled binaries

Standalone scripts written in Julia are available in `script/` directory for the end-to-end differentiable blind tip reconstruction, erosion, dilation, and RANSAC (for correcting tilt in AFM images). All the scripts read and write CSV-formatted AFM images files. For each usage, please see the ouptus of `--help` option. Compiled binaries and libraries are available (WITHOUT WARRANTY OF ANY KIND) for [Linux(X86-64) and Mac(ARM64)](https://suitc-my.sharepoint.com/:f:/g/personal/ymatsunaga_mail_saitama-u_ac_jp/EpgcrCt4Wt5Atzr6C4NL2HIBpd9CX_5w_VDQkzfKARDGCg?e=OMGb6n). 

```
$ cd script/
$ julia dblindtip.jl --help
usage: dblindtip.jl [--lambda LAMBDA] [--learning_rate LEARNING_RATE]
                    [--epochs EPOCHS] [--width WIDTH]
                    [--height HEIGHT] [--output OUTPUT] [-h] [arg1]

Perform the end-to-end differentiable blind tip reconstruction from
given AFM images

positional arguments:
  arg1                  Input directory which contains the CSV files
                        of AFM images. Read only filenames ending with
                        ".csv". Each CSV contains the heights of
                        pixels in Angstrom. Column correspond to the
                        x-axis (width). Rows are the y-axis (height).

optional arguments:
  --lambda LAMBDA       Weight for L2 regularization term (default =
                        0.00001) (type: Float64, default: 1.0e-5)
  --learning_rate LEARNING_RATE
                        Learning rate for AdamW optimier in Angstrom
                        (default = 1.0 Angstrom) (type: Float64,
                        default: 1.0)
  --epochs EPOCHS       Epochs for AdamW optimizer (type: Int64,
                        default: 100)
  --width WIDTH         Pixels used in the width of tip. Should be
                        smaller than the pixel width of AFM images
                        (default=11) (type: Int64, default: 15)
  --height HEIGHT       Pixels used in the height of tip. Should be
                        smaller than the pixel width of AFM images
                        (default=11) (type: Int64, default: 15)
  --output OUTPUT       Output file name for reconstructed tip shape
                        (default is tip.csv) (default: "tip.csv")
  -h, --help            show this help message and exit

examples:

  dblindtip.jl --output tip.csv data/
  dblindtip.jl --learning-rate 0.2 --epochs 200 --output tip.csv data/
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

