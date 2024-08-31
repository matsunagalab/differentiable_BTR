using ArgParse
using DelimitedFiles
using MDToolbox
using Random
using Statistics

# define commandline options
function parse_commandline()
    s = ArgParseSettings("Correct tilt in AFM data (ASD file or CSV files) with the RANSAC (Random Sample Consensus) algorithm. Output CSV files are created in the same direcoty of the AFM data files. \"_ransac\" is added to the file names for tilting-corrected data. \"_inlier\" is added for files containing detected inliers.")

    @add_arg_table! s begin
        "--frame_start"
            arg_type = Int64
            default = nothing
            help = "Start frame number. By default, the first frame of data is used."
        "--frame_stop"
            arg_type = Int64
            default = nothing
            help = "Last frame number. By default, the last frame of data is used."
        "--minimum_ratio_inliers"
            arg_type = Float64
            default = 0.2
            help = "The minimum percentage of inliears in the total data. If the percentage is smaller than this value, the model constructed by those inliers is ignored."
        "--cutoff_inliers"
            arg_type = Float64
            default = 2.0
            help = "If the residuals from the model constructed from random samples are within this range, a sample is considered as inlier. Assumed that the unit is nm."
        "--num_iter"
            arg_type = Int64
            default = 10000
            help = "The number of trials to fit by random sampling."
        "--nsample"
            arg_type = Int64
            default = 100
            help = "The number of random samples for each trial."
        "arg1"
            arg_type = String
            default = "./"
            help = "Input ASD file or a directory which contains CSV files (one CSV file per AFM image). If a directory is given, read only filenames ending with \".csv\". Assumed that each CSV contains the heights of pixels in nm. Columns correspond to the x-axis (width). Rows are the y-axis (height)."
    end

    s.epilog = """
        examples:\n
        \n
        \ua0\ua0julia $(basename(Base.source_path())) data/\n
        \n
        """

    return parse_args(s)
end

# define ransac
# example usage:
# 
# Random.seed!(1234)
# images_ransac, images_inliers = ransac(images, minimum_ratio_inliers=0.2, cutoff_inliers=10.0*2, nsample=50, num_iter=10000);

function linear_fitting(afms)
    nframe = length(afms)
    height, width = size(afms[1])
    T = eltype(afms[1])
    X = ones(T, nframe*height*width, 3)
    y = zeros(T, nframe*height*width)
    icount = 0
    for iframe = 1:nframe
        for h = 1:height, w = 1:width
            z = afms[iframe][h, w]
            #if abs(z) > eps(T)
                icount += 1
                y[icount] = z
                X[icount, 2] = h
                X[icount, 3] = w
            #end
        end
    end
    X = X[1:icount, :]
    y = y[1:icount]
    W = inv(X' * X) * X' * y

    afms_clean = deepcopy(afms)
    for iframe = 1:nframe
        for h = 1:height, w = 1:width
            z = afms[iframe][h, w]
            #if abs(z) > eps(T)
                afms_clean[iframe][h, w] -= W[1] + W[2]*h + W[3]*w
            #end
        end
    end
    return afms_clean
end

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
    #println("num_iter = $(num_iter)")
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
        #println("ratio_inliers: $(ratio_inliers)")
        #println("minimum_ratio_inliers: $(minimum_ratio_inliers)")
        if ratio_inliers < minimum_ratio_inliers
            continue
        end
        
        # construct model using inliers
        X_sub = X[index_inliers, :]
        y_sub = y[index_inliers]
        W = inv(X_sub' * X_sub) * X_sub' * y_sub
        rmse = sqrt.((y_sub .- (W[1] .+ W[2] .* X_sub[:, 1] .+ W[3] .* X_sub[:, 2])).^2)
        #println("rmse_min: $(rmse_min)")
        #println("rmse: $(mean(rmse))")
        if mean(rmse) < rmse_min
            rmse_min = mean(rmse)
            println("# trial = $(inum)")
            println("# best model updated: rmse = $(rmse_min)")
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


function main(args)
    parsed_args = parse_commandline()

    frame_start = parsed_args["frame_start"]
    frame_stop = parsed_args["frame_stop"]
    minimum_ratio_inliers = parsed_args["minimum_ratio_inliers"]
    cutoff_inliers = parsed_args["cutoff_inliers"]
    num_iter = parsed_args["num_iter"]
    nsample = parsed_args["nsample"]
    input = parsed_args["arg1"]

    # check whether input is a asd file or a directory
    images = []
    fnames_read = []
    if isfile(input)
        input_dir = dirname(input)
        println("# ASD file $(input) is read")
        #input_dir = dirname(input)
        #input = basename(input)
        #ext = splitext(input)[2][2:end]
        #input = splitext(input)[1]
        asd = readasd(input, unit="nm")
        images = []
        for iframe = 1:length(asd.frames)
            image = asd.frames[iframe].data
            push!(images, image)
        end
        resx = asd.header.scanningRangeX / asd.header.pixelX
        resy = asd.header.scanningRangeY / asd.header.pixelY
    else
        input_dir = input
        fnames = readdir(input_dir)
        println("# Files in $(input_dir) are read in the following order:")
        for fname in fnames
            if !isnothing(match(r".+\.csv$", fname))
                println(joinpath(input_dir, fname))
                image = readdlm(joinpath(input_dir, fname), ',')
                push!(images, image)
                push!(fnames_read, joinpath(input_dir, fname))
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
    images = images[frame_start2:frame_stop2]

    if isfile(input)
        digits = length(string(abs(frame_stop2)))
        for i = frame_start2:frame_stop2
            output = splitext(input)[1] * "_" * lpad(i, digits, '0') * ".csv"
            push!(fnames_read, output)
        end
    end

    # preprocess (linear fitting)
    images = linear_fitting(images)

    # ransac
    images_correct, images_inliers = ransac(images;
                                            minimum_ratio_inliers=minimum_ratio_inliers,
                                            cutoff_inliers=cutoff_inliers,
                                            num_iter=num_iter, nsample=nsample)

    # output
    println("# Writing the tilt-corrected images:")
    for i in 1:length(fnames_read)
        output = fnames_read[i] * "_ransac"
        println(output)
        writedlm(output, images_correct[i], ',')
    end
    println("# Writing the inlier-marked images:")
    for i in 1:length(fnames_read)
        output = fnames_read[i] * "_inlier"
        println(output)
        writedlm(output, images_inliers[i], ',')
    end

    return 0
end

main(ARGS)
