using GenerationExpansionPlanning
using TulipaClustering
using Gurobi
using JSON
using Random

config_folder = "case_studies/stylized_EU/configs_experiment"
config_files = readdir(config_folder)

for config_file in config_files
    if config_file == "test2.toml"
        Random.seed!(1234)
        config_path = joinpath(config_folder, config_file)

        @info "Reading config file $config_path"
        config = read_config(config_path)
        
        @info "Parsing the config data for $config_file"
        experiment_data = ExperimentData(config[:input])
        
        @info "Running the experiments defined by $config_path"
        experiment_result, input_data = run_experiment(experiment_data, Gurobi.Optimizer)

        @info "Saving the results of the initial run"
        output_config = config[:output]
        save_result(experiment_result, output_config)
        
        if config[:input][:rp][:use_periods]
            @info "TO DO: Save information about the representative days"

            @info "Create new input"
            config = edit_config(config, experiment_result)
            experiment_new = SecondStageData(config[:input])

            @info "Running the fixed investment experiments"	
            result_new, input_data = run_fixed_investment(experiment_new, Gurobi.Optimizer)

            # @info "Saving the input data to JSON file"
            # input_data_path = joinpath(config_folder, "newtest2.json")
            # open(input_data_path, "w") do io
            #     JSON.print(io, input_data)
            # end
            
            output_config = config[:output]
            save_result(result_new, output_config)
        end
    end

end
