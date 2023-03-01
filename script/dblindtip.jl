using ArgParse
using DelimitedFiles
using Flux
using Flux.Data: DataLoader
using Statistics
using MDToolbox

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Perform the end-to-end differentiable blind tip reconstruction from given AFM data.")

    @add_arg_table! s begin
        "--lambda"
            arg_type = Float64
            default = 0.00001
            help = "Weight for L2 regularization term."
        "--learning_rate"
            arg_type = Float64
            default = 0.1
            help = "Learning rate for AdamW optimier in nm."
        "--epochs"
            arg_type = Int64
            default = 200
            help = "Epochs for AdamW optimizer."
        "--width"
            arg_type = Int64
            default = 15
            help = "Pixels used in the width of tip. Should be smaller than the pixel width of AFM images."
        "--height"
            arg_type = Int64
            default = 15
            help = "Pixels used in the height of tip. Should be smaller than the pixel height of AFM images."
        "--ext"
            arg_type = String
            default = "csv"
            help = "Extension of input AFM csv filenames that should be recognized as inputs. E.g., --ext csv_erosion recognizes 1.csv_erosion."
        "--output"
            arg_type = String
            default = "tip.csv"
            help = "Output file name for reconstructed tip shape."
        "arg1"
            arg_type = String
            default = "./"
            help = "Input directory which contains the CSV files of AFM images. By default, read only filenames ending with \".csv\". Recognized extension can be specified with --ext option. Each CSV contains the heights of pixels in nm. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) --output tip.csv data/\n
        \ua0\ua0julia $(basename(Base.source_path())) --learning_rate 0.2 --epochs 200 --output tip.csv data/\n
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

    lambda = parsed_args["lambda"]
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

    # blind tip reconstruction
    tip = zeros(Float64, height, width)
    println("# Mean square error:")
    loss_train = dblindtip!(tip, images, lambda, nepoch=epochs, learning_rate=learning_rate)
    for l in loss_train
        println(l)
    end

    # output
    println("# Writing the reconstructed tip shape in $(output)")
    writedlm(output, tip, ',')

    return 0
end

main(ARGS)
