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
            help = "Input file name for tip shape used in dilation. Contains the heights of pixels in Angstrom. Column correspond to the x-axis (width). Rows are the y-axis (height)."
        "arg1"
            nargs = '+'
            arg_type = String
            help = "CSV file names of molecular surface images. Each CSV contains the heights of pixels in Angstrom. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0$(basename(Base.source_path())) --tip tip.csv data/afm01.csv data/afm02.csv\n
        \ua0\ua0$(basename(Base.source_path())) --tip tip.csv data/afm*.csv\n
        \n
        """

    return parse_args(s)
end


function main(args)
    parsed_args = parse_commandline()

    input_tip = parsed_args["tip"]
    inputs = parsed_args["arg1"]

    # input
    P = readdlm(input_tip, ',')

    # output
    for input in inputs
        image = readdlm(input, ',')
        image_dilation = idilation(image, P)
        #output = dirname(input) *
        output = input * "_dilation"
        writedlm(output, image_dilation, ',')
    end

    return 0
end

main(ARGS)
