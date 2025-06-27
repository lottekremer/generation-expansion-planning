using TOML

# Load the TOML file
config_path = joinpath("./case_studies/europe/configs", "start.toml")
config = TOML.parsefile(config_path)

scenario = "cross_scenario"
method = ["convex_hull", "conical_bounded", "k_means", "k_medoids"]
seed = 1:10
num_periods = [20, 50, 100]
blended = [true, false]
global experiment_id = 1

config["input"]["rp"]["use_periods"] = true
config["input"]["rp"]["clustering_type"] = scenario

for m in method
    for b in blended
        for number_of_periods in num_periods
            for s in seed
                config["input"]["rp"]["number_of_periods"] = number_of_periods
                config["input"]["rp"]["method"] = m
                config["input"]["rp"]["blended"] = b
                config["input"]["rp"]["use_initial"] = b ? "before" : "after"
                config["input"]["rp"]["initial"] = [1]
                config["input"]["data"]["rp_demand"] = "rp_demand_cross.csv"
                config["input"]["data"]["rp_generation_availability"] = "rp_generation_availability_cross.csv"
                output_name = b ? "blended_" : "extreme_"

                if m == "k_means" || m == "k_medoids"
                    config["input"]["data"]["seed"] = "seeds$(s).json"
                else
                    delete!(config["input"]["data"], "seed")
                    output_name *= "$(s)_"
                    if s > 1
                        continue
                    end
                end

                config["output"]["dir"] = output_name

                new_toml_path = "./case_studies/europe/configs/start_$(experiment_id).toml"
                open(new_toml_path, "w") do file
                    TOML.print(file, config)
                end


                global experiment_id += 1
                println("Experiment $(experiment_id) created")
            end
        end
    end
end
