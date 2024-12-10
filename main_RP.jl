using GenerationExpansionPlanning
using TulipaClustering
using Gurobi

config_folder = "case_studies/stylized_EU/configs_SP"
config_files = readdir(config_folder)

for config_file in config_files
    if config_file == "config_all_720.toml"
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

        # TODO: Implement fixed investments to check for difference in objective value
        @info "Run the results with fixed investments"
    end
end
