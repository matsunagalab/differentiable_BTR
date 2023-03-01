using ArgParse
using DelimitedFiles
using MDToolbox

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Perform erosion of AFM data with a given tip shape. Output files are created in the same direcoty of the AFM data files. _erosion is added to the file name.")

    @add_arg_table! s begin
        "--tip"
            arg_type = String
            default = "tip.csv"
            help = "Input file name for tip shape used in erosion. Contains the heights of pixels in nm. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
        "--ext"
            arg_type = String
            default = "csv"
            help = "Extension of input AFM csv filenames that should be recognized as inputs. E.g., --ext csv_erosion recognizes 1.csv_erosion."
        "arg1"
            arg_type = String
            default = "./"
            help = "Input directory which contains the CSV files of AFM images. By default, read only filenames ending with \".csv\". Recognized extension can be specified with --ext option. Each CSV contains the heights of pixels in nm. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) --tip tip.csv data/
        \n
        """

    return parse_args(s)
end


function main(args)
    parsed_args = parse_commandline()

    input_tip = parsed_args["tip"]
    ext = parsed_args["ext"]
    input_dir = parsed_args["arg1"]

    # input
    P = readdlm(input_tip, ',')

    # output
    fnames = readdir(input_dir)
    println("# Files in $(input_dir) are read in the following order:")
    for fname in fnames
        if !isnothing(match(Regex(".+\\.$(ext)" * "\$"), fname))
        #if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            image_erosion = ierosion(image, P)
            output = joinpath(input_dir, splitext(fname)[1] * ".csv_erosion")
            writedlm(output, image_erosion, ',')
        end
    end
    println("# Writing eroded images:")
    for fname in fnames
        if !isnothing(match(Regex(".+\\.$(ext)" * "\$"), fname))
        #if !isnothing(match(r".+\.csv$", fname))
            output = joinpath(input_dir, splitext(fname)[1] * ".csv_erosion")
            println(output)
        end
    end

    return 0
end

main(ARGS)
