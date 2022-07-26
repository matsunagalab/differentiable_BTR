module app

using ArgParse
using DelimitedFiles
using Flux
using Flux.Data: DataLoader
using Statistics
using MDToolbox
using Random

############################ dblindtip

# define commandline options
function parse_commandline_dblindtip()
    s = ArgParseSettings("Perform the end-to-end differentiable blind tip reconstruction from given AFM images")

    @add_arg_table! s begin
        "--lambda"
            arg_type = Float64
            default = 0.00001
            help = "Weight for L2 regularization term (default = 0.00001)"
        "--learning_rate"
            arg_type = Float64
            default = 1.0
            help = "Learning rate for AdamW optimier in Angstrom (default = 1.0 Angstrom)"
        "--epochs"
            arg_type = Int64
            default = 100
            help = "Epochs for AdamW optimizer"
        "--width"
            arg_type = Int64
            default = 15
            help = "Pixels used in the width of tip. Should be smaller than the pixel width of AFM images (default=11)"
        "--height"
            arg_type = Int64
            default = 15
            help = "Pixels used in the height of tip. Should be smaller than the pixel width of AFM images (default=11)"
        "--output"
            arg_type = String
            default = "tip.csv"
            help = "Output file name for reconstructed tip shape (default is tip.csv)"
        "arg1"
            arg_type = String
            help = "Input directory which contains the CSV files of AFM images. Read only filenames ending with \".csv\". Each CSV contains the heights of pixels in Angstrom. Column correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0$(basename(Base.source_path())) --output tip.csv data/\n
        \ua0\ua0$(basename(Base.source_path())) --learning-rate 0.2 --epochs 200 --output tip.csv data/\n
        \n
        """

    return parse_args(s)
end


# define flux layers
struct IOpen
    P::AbstractArray
end
IOpen(height::Integer, width::Integer) = IOpen(zeros(Float64, height, width))
Flux.@functor IOpen (P,)
(m::IOpen)(image) = idilation(ierosion(image, m.P), m.P)


function main_dblindtip()::Cint
    parsed_args = parse_commandline_dblindtip()

    lambda = parsed_args["lambda"]
    learning_rate = parsed_args["learning_rate"]
    epochs = parsed_args["epochs"]
    width = parsed_args["width"]
    height = parsed_args["height"]
    output = parsed_args["output"]
    input_dir = parsed_args["arg1"]

    # input
    fnames = readdir(input_dir)
    images = []
    println("Files in are read in the following order:")
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            push!(images, image)
        end
    end

    # loop
    images_randn = deepcopy(images)
    images_randn_copy = deepcopy(images)
    m = IOpen(height, width)
    loss(image_randn_copy, image_randn) = mean(Flux.Losses.mse.(m.(image_randn_copy), image_randn))
    ps = Flux.params(m)
    train_loader = Flux.Data.DataLoader((data=images_randn_copy[1:end], label=images_randn[1:end]), batchsize=1, shuffle=false);
    opt = ADAMW(learning_rate, (0.9, 0.999), lambda)
    loss_train = []
    println("Loss function:")
    for epoch in 1:epochs
        for (x, y) in train_loader
            gs = gradient(() -> loss(x, y), ps)
            Flux.Optimise.update!(opt, ps, gs)
            m.P .= min.(m.P, 0.0)
            m.P .= MDToolbox.translate_tip_peak(m.P)
        end
        tmp = loss(images_randn_copy[1:end], images_randn[1:end])
        println(tmp)
        push!(loss_train, tmp)
    end
    tip = m.P

    # output
    writedlm(output, tip, ',')

    return 0
end

############################ dilation

# define commandline options
function parse_commandline_dilation()
    s = ArgParseSettings("Perform dilation of molecular surface image with a given tip shape. Output files are created in the same direcoty of the surface image files. _dilation is added to the file name.")

    @add_arg_table! s begin
        "--tip"
            arg_type = String
            default = "tip.csv"
            help = "Input file name for tip shape used in dilation. Contains the heights of pixels in Angstrom. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
        "arg1"
            arg_type = String
            help = "Input directory which contains the CSV files of molecular surfaces. Read only filenames ending with \".csv\". Each CSV contains the heights of pixels in Angstrom. Column correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0$(basename(Base.source_path())) --tip tip.csv data/\n
        \n
        """

    return parse_args(s)
end

function main_dilation()::Cint
    parsed_args = parse_commandline_dilation()

    input_tip = parsed_args["tip"]
    input_dir = parsed_args["arg1"]

    # input
    P = readdlm(input_tip, ',')

    # output
    fnames = readdir(input_dir)
    println("Files in are read in the following order:")
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            image_dilation = idilation(image, P)
            output = joinpath(input_dir, fname) * "_dilation"
            writedlm(output, image_dilation, ',')
        end
    end

    return 0
end

############################ erosion

# define commandline options
function parse_commandline_erosion()
    s = ArgParseSettings("Perform erosion of AFM image with a given tip shape. Output files are created in the same direcoty of the AFM image files. _erosion is added to the file name.")

    @add_arg_table! s begin
        "--tip"
            arg_type = String
            default = "tip.csv"
            help = "Input file name for tip shape used in erosion. Contains the heights of pixels in Angstrom. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
        "arg1"
            arg_type = String
            help = "Input directory which contains the CSV files of AFM images. Read only filenames ending with \".csv\". Each CSV contains the heights of pixels in Angstrom. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0$(basename(Base.source_path())) --tip tip.csv data/
        \n
        """

    return parse_args(s)
end

function main_erosion()::Cint
    parsed_args = parse_commandline_erosion()

    input_tip = parsed_args["tip"]
    input_dir = parsed_args["arg1"]

    # input
    P = readdlm(input_tip, ',')

    # output
    fnames = readdir(input_dir)
    println("Files in are read in the following order:")
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            image_erosion = ierosion(image, P)
            output = joinpath(input_dir, fname) * "_erosion"
            writedlm(output, image_erosion, ',')
        end
    end

    return 0
end

############################ erosion
# define commandline options
function parse_commandline_ransac()
    s = ArgParseSettings("Correct tilt in AFM images with the RANSAC (Random Sample Consensus) algorithm. Output files are created in the same direcoty of the AFM image files. \"_ransac\" is added to the file name for tilting-corrected images. \"_inlier\" is added for images containing detected inliers.")

    @add_arg_table! s begin
        "--minimum_ratio_inliers"
            arg_type = Float64
            default = 0.2
            help = "The minimum percentage of inliears in the total data. If the percentage is smaller than this value, the model constructed by those inliers is ignored."
        "--cutoff_inliers"
            arg_type = Float64
            default = 20.0
            help = "If the residuals from the model constructed from random samples are within this range, a sample is considered as inlier."
        "--num_iter"
            arg_type = Int64
            default = 10000
            help = "The number of trials to fit by random sampling"
        "--nsample"
            arg_type = Int64
            default = 100
            help = "The number of random samples for each trial"
        "arg1"
            arg_type = String
            help = "Input directory which contains the CSV files of AFM images. Read only filenames ending with \".csv\". Each CSV contains the heights of pixels in Angstrom. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0$(basename(Base.source_path())) data/\n
        \n
        """

    return parse_args(s)
end

# define ransac
# example usage:
# 
# Random.seed!(1234)
# images_ransac, images_inliers = ransac(images, minimum_ratio_inliers=0.2, cutoff_inliers=10.0*2, nsample=50, num_iter=10000);

function ransac(afms; minimum_ratio_inliers=0.2, cutoff_inliers=10.0*2, num_iter=10000, nsample=100)
    nframe = length(afms)
    height, width = size(afms[1])
    T = eltype(afms[1])
    X = ones(T, nframe*height*width, 3)
    y = zeros(T, nframe*height*width)
    f = zeros(T, nframe*height*width)
    rmse_min = T(Inf)

    icount = 0
    for iframe = 1:nframe
        for h = 1:height, w = 1:width
            z = afms[iframe][h, w]
            #if abs(z) > eps(T)
                icount += 1
                X[icount, 2] = h
                X[icount, 3] = w
                y[icount] = z
                f[icount] = iframe
            #end
        end
    end
    X = X[1:icount, :]
    y = y[1:icount]
    f = f[1:icount]

    W_best = zeros(T, 3)
    index_inliers_best = zeros(T, icount)
    for inum = 1:num_iter
        # pick up random samples
        index = randperm(icount)[1:nsample]
        X_sub = X[index, :]
        y_sub = y[index]

        # check inliers ratio
        W = inv(X_sub' * X_sub) * X_sub' * y_sub
        rmse = sqrt.((y .- (W[1] .+ W[2] .* X[:, 1] .+ W[3] .* X[:, 2])).^2)
        index_inliers = rmse .< cutoff_inliers
        ratio_inliers = sum(index_inliers) / icount
        if ratio_inliers < minimum_ratio_inliers
            continue
        end
        
        # construct model using inliers
        X_sub = X[index_inliers, :]
        y_sub = y[index_inliers]
        W = inv(X_sub' * X_sub) * X_sub' * y_sub
        rmse = sqrt.((y_sub .- (W[1] .+ W[2] .* X_sub[:, 1] .+ W[3] .* X_sub[:, 2])).^2)
        if mean(rmse) < rmse_min
            rmse_min = mean(rmse)
            println("trial = $(inum)")
            println("best model updated: rmse = $(rmse_min)")
            W_best .= W
            index_inliers_best .= index_inliers
        end
    end

    afms_inliers = deepcopy(afms)
    for i = 1:icount
        iframe = Int(f[i])
        h = Int(X[i, 2])
        w = Int(X[i, 3])
        if index_inliers_best[i] > 0.5
            afms_inliers[iframe][h, w] = -1000.0
        end
    end

    afms_clean = deepcopy(afms)
    for iframe = 1:nframe
        for h = 1:height, w = 1:width
            z = afms[iframe][h, w]
            afms_clean[iframe][h, w] -= W_best[1] + W_best[2]*h + W_best[3]*w
       end
    end
    return afms_clean, afms_inliers
end


function main_ransac()::Cint
    parsed_args = parse_commandline_ransac()

    minimum_ratio_inliers = parsed_args["minimum_ratio_inliers"]
    cutoff_inliers = parsed_args["cutoff_inliers"]
    num_iter = parsed_args["num_iter"]
    nsample = parsed_args["nsample"]
    input_dir = parsed_args["arg1"]

    # input
    fnames = readdir(input_dir)
    images = []
    fnames_read = []
    println("Files in are read in the following order:")
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            push!(images, image)
            push!(fnames_read, fname)
        end
    end

    # ransac
    images_correct, images_inliers = ransac(images;
                                            minimum_ratio_inliers=minimum_ratio_inliers,
                                            cutoff_inliers=cutoff_inliers,
                                            num_iter=num_iter, nsample=nsample)

    # output
    for i in 1:length(fnames_read)
        output = joinpath(input_dir, fnames_read[i]) * "_ransac"
        writedlm(output, images_correct[i], ',')
        output = joinpath(input_dir, fnames_read[i]) * "_inlier"
        writedlm(output, images_inliers[i], ',')
    end

    return 0
end

end # module app
