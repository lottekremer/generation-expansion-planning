using TOML

# Define the options for each field
clustering_type_options = ["cross_scenario"]
# learning_rate = 0.01
# niter = 10000
# tol = 1e-6
distance_options = ["SqEuclidean", "CosineDist", "CityBlock"]
method_options = ["convex_hull", "k_means", "k_medoids"]
number_of_periods_options = [3, 10, 20]
period_duration = 24

# Read the original TOML file
original_toml_directory = "./case_studies/optimality/configs/"
tomls = readdir(original_toml_directory)

global experiment_id = 1
for toml in tomls
    global experiment_id = 1
    if endswith(toml, ".toml")
        original_toml_path = original_toml_directory*"/"*toml
        original_toml = TOML.parsefile(original_toml_path)
    else
        continue
    end

    # # Update the fields in the TOML data
    # original_toml["input"]["rp"]["use_periods"] = false
    # original_toml["input"]["sets"]["time_steps"] = "1:$(93*period_duration)"
    # original_toml["input"]["sets"]["scenarios"] = "auto"

    # # Write the updated TOML data to a new file
    # old_name = split(toml, ".")[1]
    # new_toml_path = "./case_studies/optimality/configs/$(old_name).toml"
    # open(new_toml_path, "w") do file
    #     TOML.print(file,original_toml)
    # end

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
                    original_toml["input"]["rp"]["use_periods"] = true
                    original_toml["input"]["rp"]["period_duration"] = period_duration

                    # Write the updated TOML data to a new file
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