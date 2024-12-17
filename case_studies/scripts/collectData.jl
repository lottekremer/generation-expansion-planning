using CSV
using DataFrames
using TOML


output_folder = "./case_studies/stylized_EU/configs_experiment/output"
folders = readdir(output_folder)

data = DataFrame(method=String[], distance=String[], num_periods=Int[], clustering=String[], 
                 avg_total_cost=Float64[], scenario_cost1900=Float64[], scenario_cost1982=Float64[], 
                 scenario_cost1987=Float64[], scenario_cost1992=Float64[], scenario_cost1995=Float64[], 
                 scenario_cost1997=Float64[], scenario_cost2002=Float64[], scenario_cost2008=Float64[], 
                 scenario_cost2009=Float64[], scenario_cost2012=Float64[], time=Float64[])

# Loop through each folder to collect the information
for folder in folders
    # Skip processing if the method is "stochastic"
    if folder == "stochastic"
        continue
    end

    # Extract method, distance, clustering, and num_periods from the folder name
    folder_parts = split(folder, "_")
    method = folder_parts[2] * "_" * folder_parts[3]
    distance = folder_parts[5]
    clustering = folder_parts[7]
    num_periods = parse(Int, folder_parts[9])

    # Read scalars.toml from fixed_investment folder
    scalars_path = joinpath(output_folder, folder, "fixed_investment", "scalars.toml")
    scalars = TOML.parsefile(scalars_path)
    total_investment_cost = scalars["total_investment_cost"]
    avg_total_cost = scalars["total_cost"]

    # Read operation_cost.csv from fixed_investment folder
    operation_cost_path = joinpath(output_folder, folder, "fixed_investment", "operational_costs.csv")
    operation_cost_data = CSV.read(operation_cost_path, DataFrame)

    # Calculate scenario costs by adding total_investment_cost to each scenario variable cost
    scenario_costs = Dict()
    for row in eachrow(operation_cost_data)
        scenario = row[:scenario]
        operation_cost = row[:operational_cost]
        scenario_costs["scenario_cost" * string(scenario)] = total_investment_cost + operation_cost
    end

    # Read the time from scalars.toml in initial_run folder
    scalars_path = joinpath(output_folder, folder, "initial_run", "scalars.toml")
    scalars = TOML.parsefile(scalars_path)
    time = scalars["runtime"]

    # Append the collected data to the main DataFrame
    push!(data, (method, distance, num_periods, clustering, avg_total_cost, 
                 scenario_costs["scenario_cost1900"], scenario_costs["scenario_cost1982"], 
                 scenario_costs["scenario_cost1987"], scenario_costs["scenario_cost1992"], 
                 scenario_costs["scenario_cost1995"], scenario_costs["scenario_cost1997"], 
                 scenario_costs["scenario_cost2002"], scenario_costs["scenario_cost2008"], 
                 scenario_costs["scenario_cost2009"], scenario_costs["scenario_cost2012"], time))
end

# Save the combined data to a new CSV file
CSV.write("combined_output.csv", data)

println("Table with all information has been created and saved as combined_output.csv")