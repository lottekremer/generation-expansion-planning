using GenerationExpansionPlanning
using DataFrames
using TulipaClustering
using Distances
using Gurobi

# Directory containing the config files
config_dir = "./case_studies/stylized_EU/test_artificial/"

# Get a list of all files in the directory
config_files = readdir(config_dir)

# Iterate over each file and read the config
for config_file in config_files
    config_path = joinpath(config_dir, config_file)
    println("Read config from: $config_path")
    config = read_config(config_path)

    # Delete the rep_period columns from the demand and generation_availability tables
    config[:input][:data][:demand] = select(config[:input][:data][:demand], Not(:rep_period))
    config[:input][:data][:generation_availability] = select(config[:input][:data][:generation_availability], Not(:rep_period))
    
    # Create the artificial month by doing k medoids clustering
    data, demand_max = process_data(config[:input][:data][:demand], config[:input][:data][:generation_availability], config[:input][:sets][:scenarios],
                                        config[:input][:rp][:period_duration], config[:input][:sets][:time_steps])
    rp = find_representative_periods(data, 30; method = :k_medoids, distance = SqEuclidean())

    # Select the selected days, process into config
    demand_res, generation_res = process_rp(rp, demand_max, 30, config[:input][:rp])
    println("Demand columns: ", names(demand_res))
    println("Generation availability columns: ", names(generation_res))
    config[:input][:rp][:periods] = 1:30
    config[:input][:rp][:period_weights] = ones(Float64, 30)
    config[:input][:data][:demand] = demand_res
    config[:input][:data][:generation_availability] = generation_res
    config[:input][:data][:time_frame] = 720
    config[:input][:sets][:time_steps] = 1:config[:input][:rp][:period_duration]
    string_columns_demand = findall(col -> eltype(col) <: AbstractString, eachcol(config[:input][:data][:demand]))
    config[:input][:data][:demand][!, string_columns_demand] = Symbol.(config[:input][:data][:demand][!, string_columns_demand])
    string_columns_generation = findall(col -> eltype(col) <: AbstractString, eachcol(config[:input][:data][:generation_availability]))
    config[:input][:data][:generation_availability][!, string_columns_generation] = Symbol.(config[:input][:data][:generation_availability][!, string_columns_generation])
    config[:input][:rp][:periods_per_scenario] = unique(Tuple.(map(collect, zip(config[:input][:data][:demand].rep_period, config[:input][:data][:demand].scenario))))

    # 1. Run those thirty days, with all periods
    config[:output][:dir] = "./case_studies/stylized_EU/test_artificial_cosineDist/original"
    @info "Parsing the config data for original"
    experiment_data = ExperimentData(config[:input])
    experiment_result, input_data = run_experiment(experiment_data, Gurobi.Optimizer)
    @info "Saving the results of original"
    save_result(experiment_result, config; fixed_investment = false)

    # 2. Select 10 days, non blended and run those
    @info "I reached non blended"
    config_nonblended = deepcopy(config)
    config_nonblended[:input][:sets][:time_steps] = 1:720
    config_nonblended[:input][:rp][:number_of_periods] = 10
    config_nonblended[:input][:rp][:use_periods] = true
    config_nonblended[:input][:rp][:blended] = false
    config_nonblended[:input][:rp][:method] = "convex_hull"
    config_nonblended[:input][:rp][:distance] = "SqEuclidean"

    config_nonblended[:input][:data][:demand][!, :time_step] .= (config_nonblended[:input][:data][:demand][!,:rep_period].-1) .* 24 .+ config_nonblended[:input][:data][:demand][!,:time_step] 
    config_nonblended[:input][:data][:generation_availability][!,:time_step] .= (config_nonblended[:input][:data][:generation_availability][!,:rep_period].-1) .* 24 .+ config_nonblended[:input][:data][:generation_availability][!,:time_step] 
    select!(config_nonblended[:input][:data][:demand], Not(:rep_period))
    select!(config_nonblended[:input][:data][:generation_availability], Not(:rep_period))

    config_blended = deepcopy(config_nonblended)
    addPeriods!(config_nonblended)
    config_nonblended[:input][:sets][:time_steps] = 1:config[:input][:rp][:period_duration]

    @info "Parsing the config data for nonblended"
    experiment_data = ExperimentData(config_nonblended[:input])
    experiment_result, input_data = run_experiment(experiment_data, Gurobi.Optimizer)
    @info "Saving the results of nonblended"
    config_nonblended[:output][:dir] = "./case_studies/stylized_EU/test_artificial_cosineDist/nonblended"
    save_result(experiment_result, config_nonblended; fixed_investment = false)
    
    @info "Create new input for fixed investment of nonblended"
    config_nonblended = edit_config(config_nonblended, experiment_result)
    experiment_new = SecondStageData(config_nonblended[:input])
    result_new, input_data = run_fixed_investment(experiment_new, Gurobi.Optimizer)
    save_result(result_new, config_nonblended; fixed_investment = true)

    # 3. Select 10 days, blended and run those
    config_blended[:input][:rp][:blended] = true
    addPeriods!(config_blended)
    config_blended[:input][:sets][:time_steps] = 1:config[:input][:rp][:period_duration]

    @info "Parsing the config data for blended"
    experiment_data = ExperimentData(config_blended[:input])
    experiment_result, input_data = run_experiment(experiment_data, Gurobi.Optimizer)
    @info "Saving the results of blended"
    config_blended[:output][:dir] = "./case_studies/stylized_EU/test_artificial_cosineDist/blended"
    save_result(experiment_result, config_blended; fixed_investment = false)
    
    @info "Create new input for fixed investment of nonblended"
    config_blended = edit_config(config_blended, experiment_result)
    experiment_new = SecondStageData(config_blended[:input])
    result_new, input_data = run_fixed_investment(experiment_new, Gurobi.Optimizer)
    save_result(result_new, config_blended; fixed_investment = true)
end
