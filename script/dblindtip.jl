using ArgParse
using DelimitedFiles
using Flux
using Flux.Data: DataLoader
using Statistics
using MDToolbox

# define commandline options
function parse_commandline()
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


function main(args)
    parsed_args = parse_commandline()

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
            m.P .= MDToolbox.translate_tip_mean(m.P)
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

main(ARGS)
