using ArgParse
using DelimitedFiles
using MDToolbox

# define commandline options
function parse_commandline()
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
        julia \ua0\ua0$(basename(Base.source_path())) --tip tip.csv data/\n
        \n
        """

    return parse_args(s)
end


function main(args)
    parsed_args = parse_commandline()

    input_tip = parsed_args["tip"]
    input_dir = parsed_args["arg1"]

    # input
    P = readdlm(input_tip, ',')

    # output
    fnames = readdir(input_dir)
    println("# Files in $(input_dir) are read in the following order:")
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            println(joinpath(input_dir, fname))
            image = readdlm(joinpath(input_dir, fname), ',')
            image_dilation = idilation(image, P)
            output = joinpath(input_dir, fname) * "_dilation"
            writedlm(output, image_dilation, ',')
        end
    end
    for fname in fnames
        if !isnothing(match(r".+\.csv$", fname))
            output = joinpath(input_dir, fname) * "_dilation"
            println("# writing the dilated images in $(output)")
        end
    end

    return 0
end

main(ARGS)
