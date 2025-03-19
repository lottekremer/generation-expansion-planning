using GenerationExpansionPlanning
using TulipaClustering
using Gurobi
using Profile

config_folder = "case_studies/optimality/configs"
config_files = readdir(config_folder)

for config_file in config_files
    if endswith(config_file, ".toml") && startswith(config_file, "closemixed_1.toml")
        config_path = joinpath(config_folder, config_file)
        start_time = @elapsed begin
        @info "Reading config file $config_path"
        config = read_config(config_path)
        end

        # Check if we need to use representative periods, do a fixed investment or normal experiment
        if haskey(config[:input], :rp) && config[:input][:rp][:use_periods]
            @info "Creating representative periods"
            process_time = @elapsed begin
            config = create_representative_periods(config)

            @info "Creating rp experiment structure"
            experiment_rp = RepData(config[:input])
            end

            @info "Running the experiment with rp"
            result = run_rp(experiment_rp, Gurobi.Optimizer)
        elseif haskey(config[:input], :fixed) && config[:input][:fixed][:fixed_run]
            @info "Adding the fixed investment details"
            process_time = @elapsed begin
            config = add_fixed_investment(config)
            
            @info "Creating fixed experiment structure"
            experiment_fixed = FixedData(config[:input])
            end

            @info "Running the fixed investment experiment"
            result = run_fixed_investment(experiment_fixed, Gurobi.Optimizer)
        else
            process_time = @elapsed begin
            @info "Creating normal experiment structure"
            experiment = ExperimentData(config[:input])
            end

            @info "Running the experiment"
            result = run_experiment(experiment, Gurobi.Optimizer)
        end
        
        process_time += start_time
        
        @info "Saving the results of the initial run"
        save_result(result, config, process_time; fixed_investment = false)
        
        if haskey(config[:input], :rp) && config[:input][:rp][:use_periods]
            @info "Create new model with investment decisions fixed"

            process_time = @elapsed begin
            @info "Creating fixed experiment structure"
            experiment_fixed = FixedData(config[:input])
            end
    
            @info "Running the fixed investment experiment"
            result = run_fixed_investment(experiment_fixed, Gurobi.Optimizer)

            @info "Saving fixed investment results"
            save_result(result, config, process_time; fixed_investment = true)
        end
    end
end
