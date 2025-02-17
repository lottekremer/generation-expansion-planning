using DataFrames
using CSV

inputs = ["inputs_centered", "inputs_close", "inputs_closer", "inputs_closest", "inputs_uniform"]
inputs = ["inputs_uniform"]

for input in inputs
    local demand = CSV.read("./case_studies/optimality/$(input)/demand.csv", DataFrame)
    local generation_availability = CSV.read("./case_studies/optimality/$(input)/generation_availability.csv", DataFrame)

    function remove_periods(df::AbstractDataFrame)
        df.time_step = (df.period .- 1) .* 24 .+ df.timestep
        select!(df, Not([:period,:timestep]))
    end

    remove_periods(demand)
    remove_periods(generation_availability)
    # select!(demand, Not(:timestep))
    # select!(generation_availability, Not(:timestep))

    CSV.write("./case_studies/optimality/$(input)/demand.csv", demand)
    CSV.write("./case_studies/optimality/$(input)/generation_availability.csv", generation_availability)
end