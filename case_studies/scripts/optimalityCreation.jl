using CSV
using DataFrames
using Random

println("Reading demand data...")
demand = CSV.read("./case_studies/optimality/inputs/demand.csv", DataFrame)
println("Demand data read successfully.")
generation_availability = CSV.read("./case_studies/optimality/inputs/generation_availability.csv", DataFrame)
println("Generation availability data read successfully.")
locations = unique(demand.location)
scenarios = unique(demand.scenario)

# println("Creating close data...")

# # Create 30 artificial days close to 1, 2, 3 with small variations in demand and generation, with every location altered in same direction
# demand_close = deepcopy(demand)
# generation_availability_close = deepcopy(generation_availability)

# sd = 0.1
# new_demand_entries = DataFrame()  # Buffer for new demand data
# new_generation_entries = DataFrame()  # Buffer for new generation data

# for i in 1:30
#     for p in [1,2,3]
#         for scenario in scenarios
#             random_factor = 1 + sd * randn()
            
#             # Filter once and modify in-place
#             demand_new = filter(row -> row.period == p && row.scenario == scenario, demand)
#             demand_new.demand .*= random_factor
#             demand_new.period .= i + 3 + 30 * (p - 1)
            
#             append!(new_demand_entries, demand_new)

#             for technology in ["SunPV", "WindOn", "WindOff"]
#                 random_factor = 1 + sd * randn()
#                 generation_new = filter(row -> row.period == p && row.technology == technology && row.scenario == scenario, generation_availability)
#                 generation_new.availability .*= random_factor
#                 generation_new.period .= i + 3 + 30 * (p - 1)

#                 append!(new_generation_entries, generation_new)
#             end
#         end
#     end
#     println("Finished day $i")	
# end

# append!(demand_close, new_demand_entries)
# append!(generation_availability_close, new_generation_entries)

# CSV.write("./case_studies/optimality/inputs_close/demand.csv", demand_close)
# CSV.write("./case_studies/optimality/inputs_close/generation_availability.csv", generation_availability_close)

# println("Creating mixed variation data...")

# # Create 30 artificial days with small variations per location
# demand_close_mixed = deepcopy(demand)
# generation_availability_close_mixed = deepcopy(generation_availability)

# sd = 0.1
# new_demand_entries = DataFrame()
# new_generation_entries = DataFrame()

# for i in 1:30
#     for p in [1,2,3]
#         for scenario in scenarios
#             println("Day $i, period $p, scenario $scenario")	
#             random_factors = Dict(location => 1 + sd * randn() for location in locations)

#             for location in locations
#                 demand_new = filter(row -> row.period == p && row.location == location && row.scenario == scenario, demand)
#                 demand_new.demand .*= random_factors[location]
#                 demand_new.period .= i + 3 + 30 * (p - 1)
                
#                 append!(new_demand_entries, demand_new)

#                 for technology in ["SunPV", "WindOn", "WindOff"]
#                     generation_new = filter(row -> row.period == p && row.technology == technology && row.location == location && row.scenario == scenario, generation_availability)
#                     generation_new.availability .*= 1 + sd * randn()
#                     generation_new.period .= i + 3 + 30 * (p - 1)

#                     append!(new_generation_entries, generation_new)
#                 end
#             end
#         end
#     end
#     println("Finished day $i")
# end

# append!(demand_close_mixed, new_demand_entries)
# append!(generation_availability_close_mixed, new_generation_entries)

# CSV.write("./case_studies/optimality/inputs_close_mixed/demand.csv", demand_close_mixed)
# CSV.write("./case_studies/optimality/inputs_close_mixed/generation_availability.csv", generation_availability_close_mixed)

# # ------------------- CONVEX COMBINATION -------------------

# println("Creating convex data...")

# demand_convex = deepcopy(demand)
# generation_availability_convex = deepcopy(generation_availability)

# new_demand_entries = DataFrame()
# new_generation_entries = DataFrame()

# for i in 1:90
#     for scenario in scenarios
#         demand_periods = [filter(row -> row.period == p && row.scenario == scenario, demand) for p in 1:3]
#         generation_periods = [filter(row -> row.period == p && row.scenario == scenario, generation_availability) for p in 1:3]

#         r = rand(3)
#         r /= sum(r)

#         demand_new = deepcopy(demand_periods[1])
#         demand_new.demand .= r[1] .* demand_periods[1].demand .+ r[2] .* demand_periods[2].demand .+ r[3] .* demand_periods[3].demand
#         demand_new.period .= i + 3
#         append!(new_demand_entries, demand_new)

#         generation_new = deepcopy(generation_periods[1])
#         generation_new.availability .= r[1] .* generation_periods[1].availability .+ r[2] .* generation_periods[2].availability .+ r[3] .* generation_periods[3].availability
#         generation_new.period .= i + 3
#         append!(new_generation_entries, generation_new)
#     end
#     println("Finished day $i")
# end

# append!(demand_convex, new_demand_entries)
# append!(generation_availability_convex, new_generation_entries)

# CSV.write("./case_studies/optimality/inputs_convex/demand.csv", demand_convex)
# CSV.write("./case_studies/optimality/inputs_convex/generation_availability.csv", generation_availability_convex)


# # ------------------- SOFTMAX COMBINATION -------------------

# println("Creating softmax data...")

# demand_softmax = deepcopy(demand)
# generation_availability_softmax = deepcopy(generation_availability)

# new_demand_entries = DataFrame()
# new_generation_entries = DataFrame()

# for i in 1:90
#     for scenario in scenarios
#         demand_periods = [filter(row -> row.period == p && row.scenario == scenario, demand) for p in 1:3]
#         generation_periods = [filter(row -> row.period == p && row.scenario == scenario, generation_availability) for p in 1:3]

#         r = exp.(rand(3) * 2 .- 1)  # Apply softmax transformation
#         r /= sum(r)

#         demand_new = deepcopy(demand_periods[1])
#         demand_new.demand .= r[1] .* demand_periods[1].demand .+ r[2] .* demand_periods[2].demand .+ r[3] .* demand_periods[3].demand
#         demand_new.period .= i + 3
#         append!(new_demand_entries, demand_new)

#         generation_new = deepcopy(generation_periods[1])
#         generation_new.availability .= r[1] .* generation_periods[1].availability .+ r[2] .* generation_periods[2].availability .+ r[3] .* generation_periods[3].availability
#         generation_new.period .= i + 3
#         append!(new_generation_entries, generation_new)
#     end
# end

# append!(demand_softmax, new_demand_entries)
# append!(generation_availability_softmax, new_generation_entries)

# CSV.write("./case_studies/optimality/inputs_softmax/demand.csv", demand_softmax)
# CSV.write("./case_studies/optimality/inputs_softmax/generation_availability.csv", generation_availability_softmax)

# ------------------- CENTERED COMBINATION -------------------

println("Creating centered data...")

demand_centered = deepcopy(demand)
generation_availability_centered = deepcopy(generation_availability)

sd = 0.1
new_demand_entries = DataFrame()
new_generation_entries = DataFrame()

demand_period_1 = filter(row -> row.period == 1, demand)
demand_period_2 = filter(row -> row.period == 2, demand)
demand_period_3 = filter(row -> row.period == 3, demand)
generation_availability_period_1 = filter(row -> row.period == 1, generation_availability)
generation_availability_period_2 = filter(row -> row.period == 2, generation_availability)
generation_availability_period_3 = filter(row -> row.period == 3, generation_availability)

demand_new = deepcopy(demand_period_1)
demand_new[!,:demand] .= (demand_period_1[!,:demand] + demand_period_2[!,:demand] + demand_period_3[!,:demand]) / 3
generation_availability_new = deepcopy(generation_availability_period_1)
generation_availability_new[!,:availability] .= (generation_availability_period_1[!,:availability] + generation_availability_period_2[!,:availability] + generation_availability_period_3[!,:availability]) / 3

for i in 1:90
    for scenario in scenarios
        random_factors = Dict(location => 1 + sd * randn() for location in locations)

        for location in locations
            demand_new2 = filter(row -> row.location == location && row.scenario == scenario, demand_new)
            demand_new2.demand *= random_factors[location]
            demand_new2.period .= i + 3
            append!(new_demand_entries, demand_new2)

            for technology in ["SunPV", "WindOn", "WindOff"]
                generation_new = filter(row -> row.technology == technology && row.location == location && row.scenario == scenario, generation_availability_new)
                generation_new.availability *= (1 + sd * randn())
                generation_new.period .= i + 3
                append!(new_generation_entries, generation_new)
            end
        end
    end
    println("Finished day $i")
end

append!(demand_centered, new_demand_entries)
append!(generation_availability_centered, new_generation_entries)

println("All data created successfully.")

CSV.write("./case_studies/optimality/inputs_centered/demand.csv", demand_centered)
CSV.write("./case_studies/optimality/inputs_centered/generation_availability.csv", generation_availability_centered)

# CSV.write("./case_studies/optimality/inputs_uniform/demand.csv", demand_centers)
# CSV.write("./case_studies/optimality/inputs_uniform/generation_availability.csv", generation_availability_centers)
