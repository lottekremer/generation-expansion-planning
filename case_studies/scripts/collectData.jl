using CSV
using DataFrames
using TOML

output_folder = "./case_studies/stylized_EU/res/5_learningrates/"
folders = readdir(output_folder)

result = DataFrame(method=String[], blended = Bool[], month = Int[], learning_rate = Float64[],
                 avg_total_cost=Float64[], time = Float64[], time_with_dispatch = Float64[], scenario = Int[], scenario_cost = Float64[])

function read_folder(folder, blended, learning_rate, df, dir)
    print("Reading folder: ", folder, "\n")
    println("Part of ", dir)
    folder_parts = split(folder, "_")
    month = parse(Int, folder_parts[7])
    method = folder_parts[4] * "_" * folder_parts[5]

    scalars_path = joinpath(dir, folder, "fixed", "scalars.toml")
    scalars = TOML.parsefile(scalars_path)
    total_investment_cost = scalars["total_investment_cost"]
    avg_total_cost = scalars["total_cost"]
    operation_cost_path = joinpath(dir, folder, "fixed", "operational_costs.csv")
    operation_cost_data = CSV.read(operation_cost_path, DataFrame)

    scalars_path_2 = joinpath(dir, folder, "initial_run", "scalars.toml")
    scalars_2 = TOML.parsefile(scalars_path_2)
    time = scalars_2["runtime"]
    time_with_dispatch = scalars_2["runtime"] + scalars["runtime"]

    for row in eachrow(operation_cost_data)
        scenario = row[:scenario]
        operation_cost = row[:operational_cost] + total_investment_cost
        push!(df, (method, blended, month, learning_rate, avg_total_cost, time, time_with_dispatch, scenario, operation_cost))
    end
end

# Loop through each folder to collect the information
for folder in folders
    # Extract method, distance, clustering, and num_periods from the folder name
    folder_parts = split(folder, "_")
    if folder_parts[1] == "nonblended"
        blended = false
        lr = 0
        subfolders = readdir(joinpath(output_folder, folder))
        for f in subfolders
            read_folder(f, blended, lr, result, joinpath(output_folder, folder))
        end
    elseif folder_parts[2] == "1"
        blended = true
        lr = 0.0001
        subfolders = readdir(joinpath(output_folder, folder))
        for f in subfolders
            read_folder(f, blended, lr, result, joinpath(output_folder, folder))
        end
    elseif folder_parts[2] == "2"
        blended = true
        lr = 0.001
        subfolders = readdir(joinpath(output_folder, folder))
        for f in subfolders
            read_folder(f, blended, lr, result, joinpath(output_folder, folder))
        end
    elseif folder_parts[2] == "3"
        blended = true
        lr = 0.01
        subfolders = readdir(joinpath(output_folder, folder))
        for f in subfolders
            read_folder(f, blended, lr, result, joinpath(output_folder, folder))
        end
    end
end

# Save the combined data to a new CSV file
CSV.write("./case_studies/stylized_EU/res/results_csv/combined_output_lr.csv", result)
println("Table with all information has been created")