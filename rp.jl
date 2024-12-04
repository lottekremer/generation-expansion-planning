module RepresentativeDays

export process_data

using TulipaClustering
using CSV
using DataFrames

function process_data(demand_file, availability_file, scenario, period_duration, timesteps)
  # Load the demand data
  demand_data = CSV.read(demand_file, DataFrame)
  generation_availability_data = CSV.read(availability_file, DataFrame)

  # Filter the data for the one scenario
  demand_data = filter(row -> row.scenario == scenario, demand_data)
  generation_availability_data = filter(row -> row.scenario == scenario, generation_availability_data)

  # Scale the demand data so that it is a value between 0 and 1 but store the max
  max_demand = maximum(demand_data.demand)
  demand_data.demand = demand_data.demand ./ max_demand

  # Rename to match the TulipaClustering names of :value and :timestep
  rename!(demand_data, :demand => :value)
  rename!(demand_data, :time_step => :timestep)
  rename!(generation_availability_data, :availability => :value)
  rename!(generation_availability_data, :time_step => :timestep)

  # Combine the demand and availability data into one dataframe in which profile_name is location_technology/demand, then timestep then value
  demand_data.location = string.(demand_data.location, "_demand")
  generation_availability_data.location = string.(generation_availability_data.location, "_", generation_availability_data.technology)
  generation_availability_data = select(generation_availability_data, :location, :timestep, :value, :scenario)
  combined_data = vcat(demand_data, generation_availability_data)
  rename!(combined_data, :location => :profile_name)

  # Only select first x timesteps time_steps
  combined_data = filter(row -> row.timestep <= timesteps, combined_data)
 
  # Split the data into periods
  split_into_periods!(combined_data; period_duration=period_duration)

  return combined_data, max_demand
end

end 