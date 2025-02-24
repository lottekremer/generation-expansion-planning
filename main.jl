using GenerationExpansionPlanning
using TulipaClustering
using Gurobi

config_folder = "case_studies/optimality/configs/"
config_files = readdir(config_folder)

for config_file in config_files
    if endswith(config_file, ".toml") && contains(config_file, "_")
        config_path = joinpath(config_folder, config_file)
        process_time = @elapsed begin
        @info "Reading config file $config_path"
        config = read_config(config_path)

        @info "Parsing the config data for $config_file"
        experiment_data = ExperimentData(config[:input])
        
        @info "Running the experiments defined by $config_path"
        experiment_result = run_experiment(experiment_data, Gurobi.Optimizer)
        end

        @info "Saving the results of the initial run"
        add_time(experiment_result, process_time)
        save_result(experiment_result, config; fixed_investment = false)
        
        if config[:input][:rp][:use_periods]
            @info "Create new model with investment decisions fixed"
            process_time = @elapsed begin
            config = edit_config(config, experiment_result)
            experiment_new = SecondStageData(config[:input])
            end

            @info "Running the fixed investment experiments"	
            result_new = run_fixed_investment(experiment_new, Gurobi.Optimizer)
            add_time(result_new, process_time)
            save_result(result_new, config; fixed_investment = true)
        end
    end
end
