using ArgParse
using DelimitedFiles
using Plots

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Create PNG image of given tip CSV file.")

    @add_arg_table! s begin
        "--cmin"
            arg_type = Float64
            default = nothing
            help = "Minimum of colorbar range. If nothing is given, determined from input data."
        "--cmax"
            arg_type = Float64
            default = nothing
            help = "Maximum of colorbar range. If nothing is given, determined from input data."
        "--resx"
            arg_type = Float64
            default = 1.0
            help = "Spatial resolution of each pixel in the X axis."
        "--resy"
            arg_type = Float64
            default = 1.0
            help = "Spatial resolution of each pixel in the Y axis."
        "arg1"
            arg_type = String
            default = "tip.csv"
            help = "Input tip CSV filename. Ouput a PNG file whose filename extension replaces the input CVS with PNG."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) tip.csv
        \n
        """

    return parse_args(s)
end


function main(args)
    parsed_args = parse_commandline()

    cmin = parsed_args["cmin"]
    cmax = parsed_args["cmax"]
    resx = parsed_args["resx"]
    resy = parsed_args["resy"]
    input = parsed_args["arg1"]
    output = splitext(input)[1] * ".png"

    # input and output
    println("# $(input) is read.")
    image = readdlm(input, ',')
    nx = size(image, 2)
    ny = size(image, 1)
    if cmin == nothing
        cmin2 = minimum(image)
    else
        cmin2 = cmin
    end
    if cmax == nothing
        cmax2 = maximum(image)
    else
        cmax2 = cmax
    end

    #pyplot()

    p = plot(collect(1:nx) .* resx, collect(1:ny) .* resy, image, st=:surface, dpi=150, clims=(cmin2, cmax2),
            aspect_ratio=:equal) #xtickfontsize=12, ytickfontsize=12, legendfontsize=12, colorbar_tickfontsize=12)
    xlabel!("X-axis")
    ylabel!("Y-axis")
    xlims!(0, nx * resx)
    ylims!(0, ny * resy)

    println("# Writing $(output).")
    savefig(p, output)

    return 0
end

main(ARGS)
