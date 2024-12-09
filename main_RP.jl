using GenerationExpansionPlanning
using TulipaClustering
# using Gurobi
using GLPK
using HiGHS

config_folder = "case_studies/stylized_EU/configs_RP"
config_files = readdir(config_folder)

for config_file in config_files
    config_path = joinpath(config_folder, config_file)

    @info "Reading config file $config_path"
    config = read_config(config_path)
    
    @info "Parsing the config data for $config_file"
    experiment_data = ExperimentData(config[:input])
    
    @info "Running the experiments defined by $config_path"
    # experiment_result = run_experiment(experiment_data, Gurobi.Optimizer)
    # experiment_result = run_experiment(experiment_data, GLPK.Optimizer)
    experiment_result = run_experiment(experiment_data, HiGHS.Optimizer)
    
    output_config = config[:output]
    save_result(experiment_result, output_config)
end
