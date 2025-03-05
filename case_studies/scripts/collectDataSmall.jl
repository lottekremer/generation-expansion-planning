using CSV
using DataFrames
using TOML

output_folder = "./case_studies/optimality/configs"
folders = readdir(output_folder)

result_in = DataFrame(method=String[], clustering = String[], seed = Int[], num_periods = Int[],
                 cost=Float64[], time = Float64[], distance = String[], data = String[], loss = Float64[], loss_ct = Int[])

result_out = DataFrame(method=String[], clustering = String[], seed = Int[], num_periods = Int[],
                cost=Float64[], time = Float64[], distance = String[], data = String[], loss = Float64[], loss_ct = Int[])

# Loop through each folder to collect the information
for folder in folders
    folder_parts = split(folder, "_")

    # If it contains mixed, we should alter the folder folder_parts
    if "mixed" in folder_parts
        folder_parts[2] = "close_mixed"
        for i in 4:length(folder_parts)
            folder_parts[i-1] = folder_parts[i]
        end
    end

    # Not an output folder
    if folder_parts[1] != "output"
        continue

    # Stochastic in the first case
    elseif folder_parts[6] == "stochastic"
        data = folder_parts[2]
        method = "stochastic"
        clustering = "stochastic"
        num_periods = 0
        seed = 0
        scalars_path = joinpath(output_folder, folder, "initial_run", "scalars.toml")
        scalars = TOML.parsefile(scalars_path)
        total_cost = scalars["total_cost"]
        time = scalars["runtime"]
        distance = "N/A"

        ## Loss
        loss_path = joinpath(output_folder, folder, "initial_run", "loss_of_load.csv")
        loss = CSV.read(loss_path, DataFrame)
        loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
        loss_ct = nrow(loss_filtered)
        loss_sum = sum(loss_filtered[:, :loss_of_load])
        if loss_ct == 0
            loss_sum = 0
        end

        push!(result_in, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

    elseif folder_parts[3] == "test" && "stochastic" in folder_parts
        data = folder_parts[2]
        method = "stochastic"
        clustering = "stochastic"
        num_periods = 0
        seed = 0
        scalars_path = joinpath(output_folder, folder, "initial_run", "scalars.toml")
        scalars = TOML.parsefile(scalars_path)
        total_cost = scalars["total_cost"]
        time = scalars["runtime"]
        distance = "N/A"
        
        ## Loss
        loss_path = joinpath(output_folder, folder, "initial_run", "loss_of_load.csv")
        loss = CSV.read(loss_path, DataFrame)
        loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
        loss_ct = nrow(loss_filtered)
        loss_sum = sum(loss_filtered[:, :loss_of_load])
        if loss_ct == 0
            loss_sum = 0
        end

        push!(result_out, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))
    
    # If close_mixed the test results are in the wrong file 
    elseif folder_parts[3] == "test"
        data = folder_parts[2]
        method = "cross_scenario"
        num_periods = parse(Int, folder_parts[7])
        clustering = folder_parts[5]
        distance = folder_parts[6]
        if clustering == "kmn"
            clustering = "k_means"
        elseif clustering == "kmd"
            clustering = "k_medoids"
        elseif clustering == "cvx"
            clustering = "convex_hull"
        end

        if distance == "sq"
            distance = "SqEuclidean"
        elseif distance == "cos"
            distance = "CosineDist"
        elseif distance == "cb"
            distance = "CityBlock"
        end

        for seedpath in readdir(joinpath(output_folder, folder))
            if contains(seedpath, "seed")
                seed = parse(Int, split(seedpath, "_")[2])
                scalars_path = joinpath(output_folder, folder, seedpath, "test", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                time = scalars["runtime"]
                
                ## Loss
                loss_path = joinpath(output_folder, folder, seedpath, "test", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_out, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

            else
                scalars_path = joinpath(output_folder, folder, "test", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                time = scalars["runtime"]
                seed = 0

                ## Loss
                loss_path = joinpath(output_folder, folder, "test", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_out, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))
            end
        end

    # If close mixed, in the other files there will be no test results
    elseif folder_parts[2] == "close_mixed"
        data = folder_parts[2]
        method = "cross_scenario"
        num_periods = parse(Int, folder_parts[6])
        clustering = folder_parts[4]
        distance = folder_parts[5]

        if clustering == "kmn"
            clustering = "k_means"
        elseif clustering == "kmd"
            clustering = "k_medoids"
        elseif clustering == "cvx"
            clustering = "convex_hull"
        end

        if distance == "sq"
            distance = "SqEuclidean"
        elseif distance == "cos"
            distance = "CosineDist"
        elseif distance == "cb"
            distance = "CityBlock"
        end

        for seedpath in readdir(joinpath(output_folder, folder))
            if contains(seedpath, "seed")
                seed = parse(Int, split(seedpath, "_")[2])
                scalars_path = joinpath(output_folder, folder, seedpath, "fixed", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                scalars_path_2 = joinpath(output_folder, folder, seedpath, "initial_run", "scalars.toml")
                scalars_2 = TOML.parsefile(scalars_path_2)
                time = scalars_2["runtime"]
                
                ## Loss
                loss_path = joinpath(output_folder, folder, seedpath, "fixed", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_in, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

            else
                scalars_path = joinpath(output_folder, folder, "fixed", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                scalars_path_2 = joinpath(output_folder, folder, "initial_run", "scalars.toml")
                scalars_2 = TOML.parsefile(scalars_path_2)
                time = scalars_2["runtime"]
                seed = 0

                ## Loss
                loss_path = joinpath(output_folder, folder, "fixed", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_in, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

                break
            end
            
        end
    
    # Finally, this is not close mixed and test are results must be in there as well
    else
        data = folder_parts[2]
        method = "cross_scenario"
        num_periods = parse(Int, folder_parts[6])
        clustering = folder_parts[4]
        distance = folder_parts[5]

        if clustering == "kmn"
            clustering = "k_means"
        elseif clustering == "kmd"
            clustering = "k_medoids"
        elseif clustering == "cvx"
            clustering = "convex_hull"
        end

        if distance == "sq"
            distance = "SqEuclidean"
        elseif distance == "cos"
            distance = "CosineDist"
        elseif distance == "cb"
            distance = "CityBlock"
        end

        for seedpath in readdir(joinpath(output_folder, folder))
            if contains(seedpath, "seed")
                ## In distribution samples
                seed = parse(Int, split(seedpath, "_")[2])
                scalars_path = joinpath(output_folder, folder, seedpath, "fixed", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                scalars_path_2 = joinpath(output_folder, folder, seedpath, "initial_run", "scalars.toml")
                scalars_2 = TOML.parsefile(scalars_path_2)
                time = scalars_2["runtime"]
                
                ## Loss
                loss_path = joinpath(output_folder, folder, seedpath, "fixed", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_in, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

                ## Out distribution samples
                scalars_path = joinpath(output_folder, folder, seedpath, "test", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                time = scalars["runtime"]

                loss_path = joinpath(output_folder, folder, seedpath, "test", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_out, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

            else
                scalars_path = joinpath(output_folder, folder, "fixed", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                scalars_path_2 = joinpath(output_folder, folder, "initial_run", "scalars.toml")
                scalars_2 = TOML.parsefile(scalars_path_2)
                time = scalars_2["runtime"]
                seed = 0

                ## Loss
                loss_path = joinpath(output_folder, folder, "fixed", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_in, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

                ## Out distribution samples
                scalars_path = joinpath(output_folder, folder, "test", "scalars.toml")
                scalars = TOML.parsefile(scalars_path)
                total_cost = scalars["total_cost"]
                time = scalars["runtime"]

                loss_path = joinpath(output_folder, folder, "test", "loss_of_load.csv")
                loss = CSV.read(loss_path, DataFrame)
                loss_filtered = filter(row -> row[:loss_of_load] >= 1e-4, loss)
                loss_ct = nrow(loss_filtered)
                loss_sum = sum(loss_filtered[:, :loss_of_load])
                if loss_ct == 0
                    loss_sum = 0
                end

                push!(result_out, (method, clustering, seed, num_periods, total_cost, time, distance, data, loss_sum, loss_ct))

                break
            end
            
        end
    end
    
end

# Save the combined data to a new CSV file
CSV.write("./case_studies/stylized_EU/res/results_csv/10_distribution_final.csv", result_in)
CSV.write("./case_studies/stylized_EU/res/results_csv/11_distribution_out.csv", result_out)
println("Table with all information has been created")