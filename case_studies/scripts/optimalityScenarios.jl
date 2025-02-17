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
    df.timestep = indices[2, :] 
end

# Splits into periods
split_into_periods(demand, 24)
split_into_periods(generation_availability, 24)

# Filter for periods 1, 150, 300
periods = [1, 150, 300]
demand_centers = filter(row -> row.period in periods, demand)
generation_availability_centers = filter(row -> row.period in periods, generation_availability)
demand_centers = filter(row -> row.scenario == 1900, demand_centers)
generation_availability_centers = filter(row -> row.scenario == 1900, generation_availability_centers)

# Renumber periods to 1, 2, 3
period_map = Dict(1 => 1, 150 => 2, 300 => 3)
demand_centers[!,"period"] = [period_map[row.period] for row in eachrow(demand_centers)]
generation_availability_centers[!,"period"] = [period_map[row.period] for row in eachrow(generation_availability_centers)]

# # Create 30 artificial days centered around 1, 2, 3 with small variations in demand and generation
# sd = 0.01
# for i in 1:30
#     for p in values(period_map)
#         random_factor = 1 + sd * randn()
#         demand_new = filter(row -> row.period == p, demand_centers)
#         demand_new[!,:demand] .= demand_new[!,:demand] .* random_factor
#         demand_new[!,:period] .= i+3+30*(p-1)

#         generation_availability_new = filter(row -> row.period == p, generation_availability_centers)
#         generation_availability_new[!,:availability] .= generation_availability_new[!,:availability] .* random_factor
#         generation_availability_new[!,:period] .= i+3 + 30*(p-1)

#         global demand_centers = vcat(demand_centers, demand_new)
#         global generation_availability_centers = vcat(generation_availability_centers, generation_availability_new)
#     end
# end

# # Create 90 artificial days with small variations in demand and generation, all centered between 1 2 and 3
# sd = 0.05
# demand_period_1 = filter(row -> row.period == 1, demand_centers)
# demand_period_2 = filter(row -> row.period == 2, demand_centers)
# demand_period_3 = filter(row -> row.period == 3, demand_centers)
# demand_mean_period = (demand_period_1[!,:demand] + demand_period_2[!,:demand] + demand_period_3[!,:demand]) / 3

# generation_availability_period_1 = filter(row -> row.period == 1, generation_availability_centers)
# generation_availability_period_2 = filter(row -> row.period == 2, generation_availability_centers)
# generation_availability_period_3 = filter(row -> row.period == 3, generation_availability_centers)
# generation_availability_mean_period = (generation_availability_period_1[!,:availability] + generation_availability_period_2[!,:availability] + generation_availability_period_3[!,:availability]) / 3

# for i in 1:90
#     random_factor = 1 + sd * randn()
#     demand_new = copy(demand_period_1)
#     demand_new[!,:demand] .= demand_mean_period .* random_factor
#     demand_new[!,:period] .= i+3

#     generation_availability_new = copy(generation_availability_period_1)
#     generation_availability_new[!,:availability] .= generation_availability_mean_period .* random_factor
#     generation_availability_new[!,:period] .= i+3

#     global demand_centers = vcat(demand_centers, demand_new)
#     global generation_availability_centers = vcat(generation_availability_centers, generation_availability_new)
# end

# Create 90 artificial days uniformly spread between 1, 2 and 3
demand_period_1 = filter(row -> row.period == 1, demand_centers)
demand_period_2 = filter(row -> row.period == 2, demand_centers)
demand_period_3 = filter(row -> row.period == 3, demand_centers)

generation_availability_period_1 = filter(row -> row.period == 1, generation_availability_centers)
generation_availability_period_2 = filter(row -> row.period == 2, generation_availability_centers)
generation_availability_period_3 = filter(row -> row.period == 3, generation_availability_centers)

for i in 1:90
    r1, r2 = rand(), rand()
    r3 = 1 - r1 - r2

    demand_new = copy(demand_period_1)
    demand_new[!,:demand] .= r1 * demand_period_1[!,:demand] .+ r2 * demand_period_2[!,:demand] .+ r3 * demand_period_3[!,:demand]
    demand_new[!,:period] .= i + 3

    generation_availability_new = copy(generation_availability_period_1)
    generation_availability_new[!,:availability] .= r1 * generation_availability_period_1[!,:availability] .+ r2 * generation_availability_period_2[!,:availability] .+ r3 * generation_availability_period_3[!,:availability]
    generation_availability_new[!,:period] .= i + 3

    global demand_centers = vcat(demand_centers, demand_new)
    global generation_availability_centers = vcat(generation_availability_centers, generation_availability_new)
end

CSV.write("./case_studies/optimality/inputs_uniform/demand.csv", demand_centers)
CSV.write("./case_studies/optimality/inputs_uniform/generation_availability.csv", generation_availability_centers)
