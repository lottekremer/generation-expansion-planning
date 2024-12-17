using TOML

# Define the options for each field
number_of_periods_options = [2, 5, 10, 15]
clustering_type_options = ["completescenario", "perscenario", "crosscenario"]
method_options = ["k_means", "k_medoids", "convex_hull"]
distance_options = ["SqEuclidean", "CosineDist", "CityBlock"]

# Read the original TOML file
original_toml_path = "./case_studies/stylized_EU/configs_experiment/rp.toml"
original_toml = TOML.parsefile(original_toml_path)

# Create the experiments
global experiment_id = 1
for number_of_periods in number_of_periods_options
    for clustering_type in clustering_type_options
        for method in method_options
            for distance in distance_options
                # Update the fields in the TOML data
                if clustering_type == "crosscenario"
                    original_toml["input"]["rp"]["number_of_periods"] = number_of_periods*10
                else
                    original_toml["input"]["rp"]["number_of_periods"] = number_of_periods
                end
                original_toml["input"]["rp"]["clustering_type"] = clustering_type
                original_toml["input"]["rp"]["method"] = method
                original_toml["input"]["rp"]["distance"] = distance
                
                # Write the updated TOML data to a new file
                new_toml_path = "./case_studies/stylized_EU/configs_experiment/rp$(experiment_id).toml"
                open(new_toml_path, "w") do file
                    TOML.print(file,original_toml)
                end
                
                global experiment_id += 1
            end
        end
    end
end