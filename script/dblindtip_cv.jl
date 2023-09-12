using ArgParse
using DelimitedFiles
using Flux
using Flux.Data: DataLoader
using Statistics
using MLBase
using Plots
using MDToolbox

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Perform cross validation and the one standard error range of MSE is plotted for the user to select an appropriate lambda value used in the subsequence blind tip reconstruction (dblindtip.jl).")

    @add_arg_table! s begin
        "--lambda_start"
            arg_type = Float64
            default = 0.00001
            help = "Min value of lambda (weight) for L2 regularization term."
        "--lambda_stop"
            arg_type = Float64
            default = 0.1
            help = "Max value of lambda (weight) for L2 regularization term."
        "--lambda_length"
            arg_type = Int64
            default = 10
            help = "The number of interpolations bewteeen Min and Max of lambda (weight) for L2 regularization term. Note that the interpolation is performed in log scale, and includes the terminal values."
        "--learning_rate"
            arg_type = Float64
            default = 0.1
            help = "Learning rate for AdamW optimier in nm."
        "--epochs"
            arg_type = Int64
            default = 300
            help = "Epochs for AdamW optimizer."
        "--width"
            arg_type = Int64
            default = 17
            help = "Pixels used in the X axis of tip shape. Should be smaller than the X pixels width of AFM images."
        "--height"
            arg_type = Int64
            default = 11
            help = "Pixels used in the Y axis of tip shape. Should be smaller than the Y-axis pixels of AFM images."
        "--ext"
            arg_type = String
            default = "csv"
            help = "Extension of input AFM csv filenames that should be recognized as inputs. E.g., --ext csv_erosion recognizes 1.csv_erosion."
        "--output"
            arg_type = String
            default = "cv.png"
            help = "Output png file name for the mean square error (MSE) plot."
        "arg1"
            arg_type = String
            default = "./"
            help = "Input directory which contains the CSV files of AFM images. By default, read only filenames ending with \".csv\". Recognized extension can be specified with --ext option. Each CSV contains the heights of pixels in nm. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) --output cv.png data/\n
        \ua0\ua0julia $(basename(Base.source_path())) --output cv.png --epochs 300 --lambda_start 1.0e-5 --lambda_stop 0.01 --lambda_length 4 data/\n
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

function dblindtip!(tip, images, lambda=0.001; nepoch=200, learning_rate=1.0)
    ny, nx = size(tip)
    images_copy = deepcopy(images)

    m = IOpen(ny, nx)
    m.P .= tip
    loss(images2, images1) = mean(Flux.Losses.mse.(m.(images2), images1))
    ps = Flux.params(m)
    train_loader = Flux.Data.DataLoader((data=images_copy, label=images), batchsize=1, shuffle=false);
    opt = ADAMW(learning_rate, (0.9, 0.999), lambda)
    
    loss_train = []
    for epoch in 1:nepoch
        for (x, y) in train_loader
            gs = gradient(() -> loss(x, y), ps)
            Flux.Optimise.update!(opt, ps, gs)
            m.P .= min.(m.P, 0.0)
            m.P .= MDToolbox.translate_tip_mean(m.P)
        end
        push!(loss_train, loss(images_copy, images))
    end
    tip .= m.P

    return loss_train
end

function main(args)
    parsed_args = parse_commandline()

    lambda_start = parsed_args["lambda_start"]
    lambda_stop = parsed_args["lambda_stop"]
    lambda_length = parsed_args["lambda_length"]
    learning_rate = parsed_args["learning_rate"]
    epochs = parsed_args["epochs"]
    width = parsed_args["width"]
    height = parsed_args["height"]
    ext = parsed_args["ext"]
    output = parsed_args["output"]
    input_dir = parsed_args["arg1"]

    # input
    fnames = readdir(input_dir)
    images = []
    println("# Files in $(input_dir) are read in the following order:")
    for fname in fnames
        if !isnothing(match(Regex(".+\\.$(ext)" * "\$"), fname))
        #if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            push!(images, image)
        end
    end

    # lambdas
    lambdas = 10.0 .^ range(log10(lambda_start), log10(lambda_stop), lambda_length)
    println("# The following lambda values used: $(lambdas)")

    # LOOCV
    println("# Performing LOOCV (leave-one-out cross validation)")

    tip = zeros(Float64, height, width)
    nframe = length(images)
    ids = collect(LOOCV(nframe))
    loss_train = zeros(Float64, nframe, length(lambdas))
    for iframe = 1:nframe
        println("# LOOCV $(iframe) / $(nframe)")
        for ilambda = 1:length(lambdas)
            tip .= zero(Float64)
            loss_tmp = dblindtip!(tip, images[ids[iframe]], lambdas[ilambda], nepoch=epochs, learning_rate=learning_rate)
            loss_train[iframe, ilambda] = loss_tmp[end]
        end
    end

    # output
    println("# Plotting the result of LOOCV in $(output)")
    loss_mean = mean(loss_train, dims=1)[:]
    loss_std = std(loss_train, dims=1)[:]
    println("# lambda  MSE(mean)  MSE(std)")
    for ilambda = 1:length(lambdas)
        println("$(lambdas[ilambda]) $(loss_mean[ilambda]) $(loss_std[ilambda])")
    end

    p = plot(lambdas, loss_mean, yerror=loss_std, xaxis=:log, framestyle=:box, 
         #markershape = :circle, 
         xlabel="lambda", ylabel="mean square error", label=nothing, 
         linewidth=2, dpi=150, fmt=:png, color=3, 
         xtickfontsize=10, ytickfontsize=10, legendfontsize=12, legend=nothing, 
         left_margin=Plots.Measures.Length(:mm, 10.0),
         right_margin=Plots.Measures.Length(:mm, 10.0),
         bottom_margin=Plots.Measures.Length(:mm, 10.0))
 
 
    i_min = argmin(loss_mean)
    p = plot!(lambdas, fill(loss_mean[i_min], length(lambdas)), 
          ribbon=fill(loss_std[i_min], length(lambdas)), 
          fillalpha=0.2, width=0.0, color=3)

    savefig(p, output)

    return 0
end

main(ARGS)
