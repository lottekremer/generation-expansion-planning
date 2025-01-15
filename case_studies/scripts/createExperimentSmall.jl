using DataFrames
using CSV

location = "GER"
time_step = 1
demand = 1000
scenario = [1,2,3,4,5,6]
sun = [0.2, 0.5, 0.6, 0.7, 0.8, 0.8]
wind = [0.5, 0.4, 0.5, 0.8, 0.2, 1.0]

demand_df = DataFrame(location = location, time_step = time_step, demand = demand, scenario = scenario)
generation_df = DataFrame(
    location = repeat([location], inner=length(scenario)*2),
    technology = repeat(["SunPV", "WindOn"], inner=length(scenario)),
    time_step = repeat([time_step], inner=length(scenario)*2),
    scenario = vcat(scenario, scenario),
    availability = vcat(sun, wind)
)

generators = CSV.read("./case_studies/stylized_EU/inputs/generation.csv", DataFrame)
generators = filter(row -> row.location == location, generators)
generators[!, :ramping] .= 0
generators = filter(row -> row.technology in ["SunPV", "WindOn", "Gas"], generators)

tranmission_lines = DataFrame()
tranmission_lines = DataFrame(
    from = String[],
    to = String[],
    export_capacity = Float64[],
    import_capacity = Float64[]
)

CSV.write("./case_studies/feasibilityExperiments/inputs/demand.csv", demand_df)
CSV.write("./case_studies/feasibilityExperiments/inputs/generation_availability.csv", generation_df)
CSV.write("./case_studies/feasibilityExperiments/inputs/generation.csv", generators)
CSV.write("./case_studies/feasibilityExperiments/inputs/transmission_lines.csv", tranmission_lines)