using TOML

# Define the options for each field
clustering_type_options = ["group_scenario", "per_scenario", "cross_scenario"]
learning_rate_options = [0.0001, 0.001, 0.01]

# Read the original TOML file
original_toml_path = "./case_studies/stylized_EU/configs_experiment/test.toml"
original_toml = TOML.parsefile(original_toml_path)
months = [1,2,3,4,5,6,7,8,9,10,11,12]

# Create the experiments
global experiment_id = 1
for clustering_type in clustering_type_options
    for month in months
        # Update the fields in the TOML data
        original_toml["input"]["rp"]["clustering_type"] = clustering_type
        original_toml["input"]["rp"]["blended"] = false
        original_toml["output"]["month"] = string(month)
        original_toml["input"]["sets"]["time_steps"] = string((month-1)*720+1)*":"*string(month*720)
        original_toml["output"]["dir"] = "nonblended"
                
        # Write the updated TOML data to a new file
        new_toml_path = "./case_studies/stylized_EU/configs_experiment/nonblended$(experiment_id).toml"
        open(new_toml_path, "w") do file
            TOML.print(file,original_toml)
        end

        experiment_blended = 1

        for learning_rate in learning_rate_options
            original_toml["input"]["rp"]["blended"] = true
            original_toml["input"]["rp"]["learning_rate"] = learning_rate
            original_toml["output"]["dir"] = "blended_$(experiment_blended)"
            new_toml_path = "./case_studies/stylized_EU/configs_experiment/blended$(experiment_id)_$(experiment_blended).toml"

            open(new_toml_path, "w") do file
                TOML.print(file,original_toml)
            end

            experiment_blended +=1

        end

        global experiment_id += 1
    end
end