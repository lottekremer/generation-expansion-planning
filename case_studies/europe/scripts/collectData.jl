using CSV
using DataFrames
using TOML

output_folder = "./case_studies/europe/configs"
folders = readdir(output_folder)

result_in = DataFrame(rp=String[], clustering=String[], seed=Int[], num_periods=Int[],
    investment_cost=Float64[], operational_cost=Float64[], runtime=Float64[], process_time=Float64[], distance=String[], data=String[], loss_ct=Int[], loss=Float64[],
    type=String[], year=String[])

result_out = DataFrame(rp=String[], clustering=String[], seed=Int[], num_periods=Int[],
    investment_cost=Float64[], operational_cost=Float64[], runtime=Float64[], process_time=Float64[], distance=String[], data=String[], loss_ct=Int[], loss=Float64[],
    type=String[], year=String[])

insample = ["1982", "1986", "1990", "1994", "1998",
    "2004", "2008", "2011", "2012", "2016"]

# Loop through each folder to collect the information
for folder in folders
    folder_parts = split(folder, "_")

    # Not an output folder
    if length(folder_parts) < 5
        continue
    else
        println("I'm busy in ...", folder)
        data = folder_parts[1]
        if length(folder_parts) >= 6
            i = 1
        else
            i = 0
        end
        num_periods = parse(Int, folder_parts[5+i])
        clustering = folder_parts[3+i]
        distance = folder_parts[4+i]
        rp = folder_parts[2+i]

        if rp == "cr"
            rp = "cross"
        end

        if clustering == "kmn"
            clustering = "k_means"
        elseif clustering == "kmd"
            clustering = "k_medoids"
        elseif clustering == "cvx"
            clustering = "convex_hull"
        elseif clustering == "cb"
            clustering = "conical_bounded"
        end

        if distance == "sq"
            distance = "SqEuclidean"
        end

        for seedpath in readdir(joinpath(output_folder, folder))
            if contains(seedpath, "seed")
                seed = parse(Int, split(seedpath, "_")[2])
                for subfolder in readdir(joinpath(output_folder, folder, seedpath))
                    scalars_path = joinpath(output_folder, folder, seedpath, subfolder, "scalars.toml")
                    scalars = TOML.parsefile(scalars_path)
                    investment = scalars["total_investment_cost"]
                    operational = scalars["total_operational_cost"]
                    runtime = scalars["runtime"]
                    process = scalars["process_time"]

                    ## Loss
                    loss_path = joinpath(output_folder, folder, seedpath, subfolder, "loss_of_load.csv")
                    loss = CSV.read(loss_path, DataFrame)

                    if !isempty(loss)
                        loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                        loss_ct = nrow(loss_filtered)
                        loss_sum = sum(loss_filtered[:, :loss_of_load])
                    else
                        loss_ct = 0
                        loss_sum = 0.0
                    end

                    if subfolder == "initial_run"
                        year = "initial"
                        type = "initial"
                    else
                        year = replace(subfolder, "test" => "")
                        if year in insample
                            type = "insample"
                        else
                            type = "outsample"
                        end
                    end
                    push!(result_in, (rp, clustering, seed, num_periods, investment, operational, runtime, process, distance, data, loss_ct, loss_sum, type, year))
                end
            elseif !contains(seedpath, "seed")
                if i == 1
                    seed = parse(Int, folder_parts[2])
                else
                    seed = 0
                end
                scalars_path = joinpath(output_folder, folder, seedpath, "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                investment = scalars["total_investment_cost"]
                operational = scalars["total_operational_cost"]
                runtime = scalars["runtime"]
                process = scalars["process_time"]

                ## Loss
                loss_path = joinpath(output_folder, folder, seedpath, "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)

                if !isempty(loss)
                    loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                    loss_ct = nrow(loss_filtered)
                    loss_sum = sum(loss_filtered[:, :loss_of_load])
                else
                    loss_ct = 0
                    loss_sum = 0.0
                end

                if seedpath == "initial_run"
                    year = "initial"
                    type = "initial"
                else
                    year = replace(seedpath, "test" => "")
                    if year in insample
                        type = "insample"
                    else
                        type = "outsample"
                    end
                end
                push!(result_in, (rp, clustering, seed, num_periods, investment, operational, runtime, process, distance, data, loss_ct, loss_sum, type, year))
            end
        end
    end

end

# Save the combined data to a new CSV file
CSV.write("./case_studies/europe/results/cross_new.csv", result_in)
println("Table with all information has been created")