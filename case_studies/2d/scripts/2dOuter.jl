using CSV
using DataFrames
using Random

Random.seed!(1234)

demand = CSV.read("./case_studies/stylized_EU/inputs/demand.csv", DataFrame)
generation_availability = CSV.read("./case_studies/stylized_EU/inputs/generation_availability.csv", DataFrame)
generation = CSV.read("./case_studies/stylized_EU/inputs/generation.csv", DataFrame)
transmission_lines = CSV.read("./case_studies/stylized_EU/inputs/transmission_lines.csv", DataFrame)

function split_into_periods(df::AbstractDataFrame, period_duration::Int)
    indices = fldmod1.(df.timestep, period_duration)
    indices = reinterpret(reshape, Int, indices)
    df.period = indices[1, :]
    df.timestep = indices[2, :]
end

# Splits into periods
split_into_periods(demand, 24)
split_into_periods(generation_availability, 24)

# Only look into the Netherlands
demand = filter(row -> row.location == "GER" && row.scenario == 1900 && row.timestep == 12, demand)
generation_availability = filter(row -> row.location == "GER" && row.scenario == 1900 && row.timestep == 12, generation_availability)
generation = filter(row -> row.location == "GER", generation)
empty!(transmission_lines)

# Remove WindOff and SunPV from generation_availability and generation
generation_availability = filter(row -> row.technology != "WindOff" && row.technology != "SunPV", generation_availability)
generation = filter(row -> row.technology != "WindOff" && row.technology != "SunPV", generation)

# Find min and max demand from demand and WindOn from generation_availability
min_demand = minimum(demand.demand)
max_demand = maximum(demand.demand)
min_wind = minimum(generation_availability.availability)
max_wind = maximum(generation_availability.availability)

println("Min demand: ", min_demand)
println("Max demand: ", max_demand)
println("Min wind: ", min_wind)
println("Max wind: ", max_wind)

# Create an elipse with as top and bottem values min demand and max demand and as left and and right value min wind and max wind
t = range(0, 2π, length=198)
generation_values = (min_wind + max_wind) / 2 .+ (max_wind - min_wind) / 4 .* cos.(t) .* 2
demand_values = (min_demand + max_demand) / 2 .+ (max_demand - min_demand) / 2 .* sin.(t) .* 2

demand = DataFrame(period=1:198, timestep=1, scenario=1900, location="GER", demand=demand_values)
generation_availability = DataFrame(period=1:198, timestep=1, scenario=1900, location="GER", availability=generation_values, technology="WindOn")
println("Demand: ", demand)
println("Generation Availability: ", generation_availability)

CSV.write("./case_studies/2d/inputs_outer/demand.csv", demand)
CSV.write("./case_studies/2d/inputs_outer/generation_availability.csv", generation_availability)
CSV.write("./case_studies/2d/inputs_outer/generation.csv", generation)
CSV.write("./case_studies/2d/inputs_outer/transmission_lines.csv", transmission_lines)
