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
years = [1900, 1982, 1987, 1992, 1995, 1997, 2002, 2008, 2009, 2012]  # Replace with the desired years
average_cost = collect_total_costs_and_compute_average(directory, years)
println("The average total cost for years $years is $average_cost")