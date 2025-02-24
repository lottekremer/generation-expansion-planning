using CSV
using DataFrames
using Random
Random.seed!(1234)

demand = CSV.read("./case_studies/stylized_EU/inputs/demand.csv", DataFrame)
generation_availability = CSV.read("./case_studies/stylized_EU/inputs/generation_availability.csv", DataFrame)

function split_into_periods(df::AbstractDataFrame, period_duration::Int)
    indices = fldmod1.(df.time_step, period_duration)
    indices = reinterpret(reshape, Int, indices)
    df.period = indices[1, :]    
    df.time_step = indices[2, :] 
end

# Splits into periods
split_into_periods(demand, 24)
split_into_periods(generation_availability, 24)

# Filter for periods 1, 150, 300
periods = [1, 150, 300]
demand_centers = filter(row -> row.period in periods, demand)
generation_availability_centers = filter(row -> row.period in periods, generation_availability)

# Renumber periods to 1, 2, 3
period_map = Dict(1 => 1, 150 => 2, 300 => 3)
demand_centers[!,"period"] = [period_map[row.period] for row in eachrow(demand_centers)]
generation_availability_centers[!,"period"] = [period_map[row.period] for row in eachrow(generation_availability_centers)]

CSV.write("./case_studies/optimality/inputs/demand.csv", demand_centers)
CSV.write("./case_studies/optimality/inputs/generation_availability.csv", generation_availability_centers)