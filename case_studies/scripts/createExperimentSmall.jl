using DataFrames
using CSV

locations = ["GER","NED"]
time_step = 1
demand = 1000
scenario = [1,2,3,4,5,6]
sun_Ger = [0.2, 0.5, 0.6, 0.7, 0.8, 0.8]
sun_Ned = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
wind_Ger = [0.5, 0.4, 0.5, 0.8, 0.2, 1.0]
wind_Ned = [0.4, 0.3, 0.5, 0.7, 0.1, 0.9]

# demand_df = DataFrame(location = locations, time_step = time_step, demand = demand, scenario = scenario)
generation_df = DataFrame(
    location = repeat(locations, inner=length(scenario)*2),
    technology = repeat(["SunPV", "WindOn"], inner=length(scenario), outer=length(locations)),
    time_step = repeat([time_step], inner=length(scenario)*2*length(locations)),
    scenario = repeat(scenario, outer=2*length(locations)),
    availability = vcat(sun_Ger, wind_Ger, sun_Ned, wind_Ned)
)

generation_df = sort(generation_df, :scenario)

generators = CSV.read("./case_studies/stylized_EU/inputs/generation.csv", DataFrame)
generators = filter(row -> row.location in locations, generators)
generators[!, :ramping] .= 0
generators = filter(row -> row.technology in ["SunPV", "WindOn", "Gas"], generators)

tranmission_lines = DataFrame(
    from = "NED",
    to = "GER",
    export_capacity = 100,
    import_capacity = 200)

# CSV.write("./case_studies/feasibilityExperiments/inputs/demand.csv", demand_df)
CSV.write("./case_studies/feasibilityExperiment_2/inputs/generation_availability.csv", generation_df)
CSV.write("./case_studies/feasibilityExperiment_2/inputs/generation.csv", generators)
CSV.write("./case_studies/feasibilityExperiment_2/inputs/transmission_lines.csv", tranmission_lines)