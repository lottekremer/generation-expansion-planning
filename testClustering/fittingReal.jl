using GenerationExpansionPlanning
using TulipaClustering
using Gurobi

config_folder = "./case_studies/stylized_EU/test_wholeyear_moreRP/"
config_files = readdir(config_folder)

for config_file in config_files
    if endswith(config_file, ".toml")
        config_path = joinpath(config_folder, config_file)

        @info "Reading config file $config_path"
        config = read_config(config_path)
        
        @info "Parsing the config data for $config_file"
        experiment_data = ExperimentData(config[:input])
        
        @info "Running the experiments defined by $config_path"
        experiment_result, input_data = run_experiment(experiment_data, Gurobi.Optimizer)

        @info "Saving the results of the initial run"
        save_result(experiment_result, config; fixed_investment = false)
        
        if config[:input][:rp][:use_periods]

            @info "Create new input"
            config = edit_config(config, experiment_result)
            experiment_new = SecondStageData(config[:input])

            @info "Running the fixed investment experiments"	
            result_new, input_data = run_fixed_investment(experiment_new, Gurobi.Optimizer)

            save_result(result_new, config; fixed_investment = true)
        end
    end
end
