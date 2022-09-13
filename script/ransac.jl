using ArgParse
using DelimitedFiles
using MDToolbox
using Random

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Perform erosion of AFM image with a given tip shape. Output files are created in the same direcoty of the AFM image files. _erosion is added to the file name.")

    @add_arg_table! s begin
        "--tip"
            arg_type = String
            default = "tip.csv"
            help = "Input file name for tip shape used in erosion. Contains the heights of pixels in Angstrom. Column correspond to the x-axis (width). Rows are the y-axis (height)."
        "arg1"
            nargs = '+'
            arg_type = String
            help = "CSV file names of AFM images. Each CSV contains the heights of pixels in Angstrom. Column correspond to the x-axis (width). Rows are the y-axis (height)."
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

# define ransac
# example usage:
# 
# Random.seed!(1234)
# images, images_inliers = ransac(images, minimum_ratio_inliers=0.2, cutoff_inliers=10.0*2, nsample=50, num_iter=10000);

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
            if abs(z) > eps(T)
                icount += 1
                X[icount, 2] = h
                X[icount, 3] = w
                y[icount] = z
                f[icount] = iframe
            end
        end
    end
    X = X[1:icount, :]
    y = y[1:icount]
    f = f[1:icount]
    #W = inv(X' * X) * X' * y

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
            W_best .= W
            index_inliers_best .= index_inliers
            @show rmse_min
        end
    end

    @show W_best
    #afms_clean = deepcopy(afms)
    afms_inliers = deepcopy(afms)
    for i = 1:icount
        iframe = Int(f[i])
        h = Int(X[i, 2])
        w = Int(X[i, 3])
        #afms_clean[iframe][h, w] -= W_best[1] + W_best[2]*T(h) + W_best[3]*T(w)
        if index_inliers_best[i] > 0.5
            afms_inliers[iframe][h, w] = -100.0
        end
    end

    afms_clean = deepcopy(afms)
    for iframe = 1:nframe
        for h = 1:height, w = 1:width
            z = afms[iframe][h, w]
            if abs(z) > eps(T)
                afms_clean[iframe][h, w] -= W_best[1] + W_best[2]*h + W_best[3]*w
            else
                #afms_clean[iframe][h, w] += rmse_min * randn()
            end
       end
    end
    return afms_clean, afms_inliers
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
        image_erosion = ierosion(image, P)
        #output = dirname(input) *
        output = input * "_erosion"
        writedlm(output, image_erosion, ',')
    end

    return 0
end

main(ARGS)
