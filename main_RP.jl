using GenerationExpansionPlanning
using TulipaClustering
using Gurobi
using CSV
using JSON

config_folder = "case_studies/stylized_EU/configs_test"
config_files = readdir(config_folder)

for config_file in config_files
    if config_file != "output" && config_file == "test2.toml"
        config_path = joinpath(config_folder, config_file)

        @info "Reading config file $config_path"
        config = read_config(config_path)
        
        @info "Parsing the config data for $config_file"
        experiment_data = ExperimentData(config[:input])
        
        @info "Running the experiments defined by $config_path"
        experiment_result = run_experiment(experiment_data, Gurobi.Optimizer)

        @info "Saving the results of the initial run"
        output_config = config[:output]
        save_result(experiment_result, output_config)
        
        if config[:input][:rp][:use_periods]
            @info "Run the results with fixed investments"
            config[:input][:rp][:use_periods] = false
            config[:input][:data][:demand] = config[:input][:data][:old_demand]
            config[:input][:data][:generation_availability] = config[:input][:data][:old_generation]

            # Set demand and generation availability to have a rep_period of 1 and weights to one as well
            config[:input][:data][:demand][!, :rep_period] = ones(Int, size(config[:input][:data][:demand], 1))
            config[:input][:data][:generation_availability][!, :rep_period] = ones(Int, size(config[:input][:data][:generation_availability], 1))
            config[:input][:rp][:periods] = [1]
            config[:input][:rp][:period_weights] = [1.0]

            # Create new experiment
            experiment_new = ExperimentData(config[:input])
            result_new = run_fixed_investment(experiment_new, Gurobi.Optimizer; initial_result=experiment_result)
            output_config = config[:output]
            save_result(result_new, output_config)
        end
    end

end
