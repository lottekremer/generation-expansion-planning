using CSV
using DataFrames

insample = [1982, 1986, 1990, 1994, 1998,
    2004, 2008, 2011, 2012, 2016]

demand = CSV.read("./case_studies/europe/inputs/rp_demand.csv", DataFrame)
generation = CSV.read("./case_studies/europe/inputs/rp_generation_availability.csv", DataFrame)

rp_demand = DataFrame()
rp_generation_availability = DataFrame()
i = 1
for timestep in unique(demand.timestep)
    for location in unique(demand.location)
        max_demand = maximum(filter(row -> row.location == location && row.timestep == timestep, demand).demand)
        new_row = DataFrame(location=location, period=i, timestep=timestep, demand=max_demand, scenario="cross")
        append!(rp_demand, new_row)

        for tech in unique(filter(row -> row.location == location, generation).technology)
            tech_data = filter(row -> row.technology == tech && row.timestep == timestep && row.location == location, generation)
            demand_data = filter(row -> row.location == location && row.timestep == timestep, demand)

            # Join tech_data and demand_data on period and scenario
            joined_data = innerjoin(
                select(tech_data, Not([:location, :timestep])),
                demand_data,
                on=[:scenario, :period]
            )

            joined_data.ratio = joined_data.availability ./ joined_data.demand

            min_ratio = minimum(joined_data.ratio)
            min_availability = min_ratio * max_demand

            new_row = DataFrame(location=location, period=i, timestep=timestep, technology=tech, availability=min_availability, scenario="cross")
            append!(rp_generation_availability, new_row)
        end
    end
end

CSV.write("./case_studies/europe/inputs/rp_demand_cross.csv", rp_demand)
CSV.write("./case_studies/europe/inputs/rp_generation_availability_cross.csv", rp_generation_availability)