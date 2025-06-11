using TOML

# Define the options for each field
clustering_type_options = ["cross_scenario"]
distance_options = ["CosineDist", "SqEuclidean"]
method_options = ["convex_hull"]
number_of_periods_options = 2:2:40
period_duration = 24
seeds = 1:10

# Read the original TOML file
original_toml_directory = "./case_studies/optimality/configs/"
tomls = readdir(original_toml_directory)

global experiment_id = 1
for toml in tomls
    global experiment_id = 1
    if endswith(toml, "closemixed.toml")
        original_toml_path = original_toml_directory*"/"*toml
        original_toml = TOML.parsefile(original_toml_path)
    else
        continue
    end

    # # Update the fields in the TOML data
    original_toml["input"]["rp"]["use_periods"] = true

    # Create the experiments
    for clustering_type in clustering_type_options
        for distance in distance_options
            for method in method_options
                for number_of_periods in number_of_periods_options
                        # Update the fields in the TOML data
                        original_toml["input"]["rp"]["clustering_type"] = clustering_type
                        original_toml["input"]["rp"]["distance"] = distance
                        original_toml["input"]["rp"]["method"] = method
                        original_toml["input"]["rp"]["number_of_periods"] = number_of_periods
                        original_toml["input"]["rp"]["blended"] = false
                        original_toml["input"]["rp"]["period_duration"] = period_duration
                        if haskey(original_toml["input"]["data"], "seed")
                            delete!(original_toml["input"]["data"], "seed")
                        end

                        old_name = split(toml, ".")[1]
                        new_toml_path = "./case_studies/optimality/configs/$(old_name)_$(experiment_id).toml"
                        open(new_toml_path, "w") do file
                            TOML.print(file,original_toml)
                        end

                        global experiment_id += 1
                        println("Experiment $(experiment_id) created")
                end
            end
        end
    end
end