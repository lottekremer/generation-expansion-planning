using CSV
using DataFrames
using TOML

output_folder = "./case_studies/optimality/configs"
folders = readdir(output_folder)

result = DataFrame(method=String[], clustering = String[], blended = Bool[], num_periods = Int[],
                 cost=Float64[], time = Float64[], distance = String[], data = String[])

# Loop through each folder to collect the information
for folder in folders
    # Extract method, distance, clustering, and num_periods from the folder name
    folder_parts = split(folder, "_")

    if folder_parts[1] != "output"
        continue
    elseif folder_parts[6] == "stochastic"
        data = folder_parts[2]
        method = "stochastic"
        clustering = "stochastic"
        blended = false
        num_periods = 0
        scalars_path = joinpath(output_folder, folder, "initial_run", "scalars.toml")
        scalars = TOML.parsefile(scalars_path)
        total_cost = scalars["total_cost"]
        time = scalars["runtime"]
        distance = "N/A"	
    elseif length(folder_parts) < 4
        continue
    else
        data = folder_parts[2]
        method = "cross_scenario"
        num_periods = parse(Int, folder_parts[6])
        blended = false
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

        scalars_path = joinpath(output_folder, folder, "fixed", "scalars.toml")
        scalars = TOML.parsefile(scalars_path)
        total_cost = scalars["total_cost"]
        scalars_path_2 = joinpath(output_folder, folder, "initial_run", "scalars.toml")
        scalars_2 = TOML.parsefile(scalars_path_2)
        time = scalars_2["runtime"]
    end
    
    push!(result, (method, clustering, blended, num_periods, total_cost, time, distance, data))
end

# Save the combined data to a new CSV file
CSV.write("./case_studies/stylized_EU/res/results_csv/9_distribution.csv", result)
println("Table with all information has been created")