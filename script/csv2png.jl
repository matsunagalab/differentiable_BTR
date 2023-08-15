using ArgParse
using DelimitedFiles
using Plots
using MDToolbox

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Create PNG images of given AFM data files. PNG files are created in the same direcoty of the AFM data files.")

    @add_arg_table! s begin
        "--frame_start"
            arg_type = Int64
            default = nothing
            help = "Start frame number. By default, the first frame of data is used."
        "--frame_stop"
            arg_type = Int64
            default = nothing
            help = "Last frame number. By default, the last frame of data is used."
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
        "--ext"
            arg_type = String
            default = "csv"
            help = "Extension of input AFM csv filenames that should be recognized as inputs. E.g., --ext csv_erosion recognizes 1.csv_erosion."
        "arg1"
            arg_type = String
            default = "./"
            help = "Input directory which contains the CSV files of AFM images. By default, read only filenames ending with \".csv\". Recognized extension can be specified with --ext option. Each CSV contains the heights of pixels. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) afm.asd
        \n
        \ua0\ua0julia $(basename(Base.source_path())) data/
        \n
        \ua0\ua0julia $(basename(Base.source_path())) --ext csv_erosion data/
        \n
        \ua0\ua0julia $(basename(Base.source_path())) --ext csv_inlier --cmin 0.0 data/
        \n
        """

    return parse_args(s)
end


function main(args)
    parsed_args = parse_commandline()

    frame_start = parsed_args["frame_start"]
    frame_stop = parsed_args["frame_stop"]
    cmin = parsed_args["cmin"]
    cmax = parsed_args["cmax"]
    resx = parsed_args["resx"]
    resy = parsed_args["resy"]
    ext = parsed_args["ext"]
    input = parsed_args["arg1"]

    # check whether input is a asd file or a directory
    images = []
    fnames_read = []
    if isfile(input)
        println("# ASD file $(input) is read")
        #input_dir = dirname(input)
        #input = basename(input)
        #ext = splitext(input)[2][2:end]
        #input = splitext(input)[1]
        asd = readasd(input)
        for iframe = 1:length(asd.frames)
            image = asd.frames[iframe].data
            push!(images, image)
        end
        resx = asd.header.scanningRangeX / asd.header.pixelX
        resy = asd.header.scanningRangeY / asd.header.pixelY
    else
        #input_dir = input
        #input = ""
        input_dir = input
        fnames = readdir(input_dir)
        println("# CSV files in $(input_dir) are read in the following order:")
        for fname in fnames
            if !isnothing(match(Regex(".+\\.$(ext)" * "\$"), fname))
                println(joinpath(input_dir, fname))
                image = readdlm(joinpath(input_dir, fname), ',')
                push!(fnames_read, fname)
                push!(images, image)
            end
        end
    end

    if frame_start != nothing
        frame_start2 = frame_start
    else
        frame_start2 = 1
    end
    if frame_stop != nothing
        frame_stop2 = frame_stop
    else
        frame_stop2 = length(images)
    end

    println("# Writing PNG images:")
    for i = frame_start2:frame_stop2
        nx = size(images[i], 2)
        ny = size(images[i], 1)
        if cmin == nothing
            cmin2 = minimum(images[i])
        else
            cmin2 = cmin
        end
        if cmax == nothing
            cmax2 = maximum(images[i])
        else
            cmax2 = cmax
        end
        heatmap(collect(1:nx) .* resx, collect(1:ny) .* resy, images[i], clim=(cmin2, cmax2), dpi=150, fmt=:png, 
                aspect_ratio=:equal) #xtickfontsize=12, ytickfontsize=12, legendfontsize=12, colorbar_tickfontsize=12)
        xlabel!("X-axis")
        ylabel!("Y-axis")
        xlims!(0, nx * resx)
        ylims!(0, ny * resy)
        p = title!("frame $(i)")
        if isfile(input)
            digits = length(string(abs(frame_stop2)))
            output = splitext(input)[1] * "_" * lpad(i, digits, '0') * ".png"
        else
            input_dir = input
            output = joinpath(input_dir, splitext(fnames_read[i])[1] * ".png")
        end
        println(output)
        savefig(p, output)
    end

    return 0
end

main(ARGS)
