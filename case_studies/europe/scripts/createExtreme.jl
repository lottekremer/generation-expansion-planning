using CSV
using DataFrames

insample = [1982, 1986, 1990, 1994, 1998,
    2004, 2008, 2011, 2012, 2016]

demand = CSV.read("./case_studies/europe/inputs/demand.csv", DataFrame)
demand = filter(row -> row.scenario in insample, demand)

generation = CSV.read("./case_studies/europe/inputs/generation_availability.csv", DataFrame)
generation = filter(row -> row.scenario in insample, generation)

rp_demand = DataFrame()
rp_generation_availability = DataFrame()
global i = 0

for scenario in insample
    global i += 1
    for timestep in unique(demand.timestep)
        for location in unique(demand.location)
            max_demand = maximum(filter(row -> row.location == location && row.timestep == timestep && row.scenario == scenario, demand).demand)
            new_row = DataFrame(location=location, period=i, timestep=timestep, demand=max_demand, scenario=scenario)
            append!(rp_demand, new_row)

            for tech in unique(filter(row -> row.location == location, generation).technology)
                tech_data = filter(row -> row.technology == tech && row.timestep == timestep && row.location == location && row.scenario == scenario, generation)
                demand_data = filter(row -> row.location == location && row.timestep == timestep && row.scenario == scenario, demand)

                # Join tech_data and demand_data on period and scenario
                joined_data = innerjoin(
                    select(tech_data, Not([:location, :timestep, :scenario])),
                    demand_data,
                    on=[:period]
                )

                joined_data.ratio = joined_data.availability ./ joined_data.demand

                min_ratio = minimum(joined_data.ratio)
                min_availability = min_ratio * max_demand

                new_row = DataFrame(location=location, period=i, timestep=timestep, technology=tech, availability=min_availability, scenario=scenario)
                append!(rp_generation_availability, new_row)
            end
        end
    end
end

CSV.write("./case_studies/europe/inputs/rp_demand.csv", rp_demand)
CSV.write("./case_studies/europe/inputs/rp_generation_availability.csv", rp_generation_availability)