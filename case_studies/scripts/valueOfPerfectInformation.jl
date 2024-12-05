using TOML
using Statistics

function collect_total_costs_and_compute_average(directory::String, years::Vector{Int})
    total_costs = []
    for year in years
        subdirectory = joinpath(directory, "result_$(year)_720")
        if isdir(subdirectory)
            filepath = joinpath(subdirectory, "scalars.toml")
            if isfile(filepath)
                data = TOML.parsefile(filepath)
                if haskey(data, "total_investment_cost") && haskey(data, "total_operational_cost")
                    total_cost = data["total_investment_cost"] + data["total_operational_cost"]
                    push!(total_costs, total_cost)
                end
            end
        end
    end
    average_cost = mean(total_costs)
    return average_cost
end

directory = "./case_studies/stylized_EU/output"
years = [1900, 1982, 1987, 1992, 1995, 1997, 2002, 2008, 2009, 2012] 
average_cost = collect_total_costs_and_compute_average(directory, years)
println("The average total cost for years $years is $average_cost")
# Compute the total cost for the "result_all_720" directory
all_directory = joinpath(directory, "result_all_720")
all_filepath = joinpath(all_directory, "scalars.toml")

if isfile(all_filepath)
    all_data = TOML.parsefile(all_filepath)
    if haskey(all_data, "total_investment_cost") && haskey(all_data, "total_operational_cost")
        all_total_cost = all_data["total_investment_cost"] + all_data["total_operational_cost"]
        println("The total cost for 'result_all_720' is $all_total_cost")
        println("The difference between the average cost and 'result_all_720' cost is $(all_total_cost - average_cost)")
    else
        println("The 'scalars.toml' file in 'result_all_720' does not contain the required keys.")
    end
else
    println("The 'scalars.toml' file in 'result_all_720' does not exist.")
end