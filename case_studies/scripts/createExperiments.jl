using TOML

# Define the options for each field
clustering_type_options = ["cross_scenario"]
distance_options = ["CosineDist", "SqEuclidean"]
method_options = ["k_means", "k_medoids", "convex_hull"]
number_of_periods_options = 3:2:41
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
    original_toml["input"]["rp"]["use_periods"] = false
    if !haskey(original_toml, "test")
        original_toml["test"] = Dict()
    end
    original_toml["test"]["run"] = true
    # original_toml["input"]["sets"]["time_steps"] = "1:$(90*period_duration)"
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
                    if method != "convex_hull"
                        
                        for seed in seeds
                            # Update the fields in the TOML data
                            original_toml["input"]["rp"]["clustering_type"] = clustering_type
                            original_toml["input"]["rp"]["distance"] = distance
                            original_toml["input"]["rp"]["method"] = method
                            original_toml["input"]["rp"]["number_of_periods"] = number_of_periods
                            original_toml["input"]["rp"]["blended"] = false
                            original_toml["input"]["rp"]["period_duration"] = period_duration
                            original_toml["input"]["data"]["seed"] = seed

                            old_name = split(toml, ".")[1]
                            # dir = "output_$(old_name)_cr_"
                            dir = "output_close_mixed_cr_"
                            if method == "k_means"
                                dir *= "kmn_"
                            elseif method == "k_medoids"
                                dir *= "kmd_"
                            elseif method == "convex_hull"
                                dir *= "cvx_"
                            end

                            if distance == "CosineDist"
                                dir *= "cos_"
                            elseif distance == "SqEuclidean"
                                dir *= "sq_"
                            end

                            dir *= "$(number_of_periods)"
                            dir *= "/seed_$(seed)"

                            dir *= "/fixed"
                            original_toml["test"]["dir"] = dir
                            original_toml["input"]["data"]["investment"] = "investment.csv"
                            original_toml["input"]["data"]["cost"] = "scalars.toml"

                            # Write the updated TOML data to a new file
                            old_name = split(toml, ".")[1]
                            new_toml_path = "./case_studies/optimality/configs/$(old_name)_$(experiment_id).toml"
                            open(new_toml_path, "w") do file
                                TOML.print(file,original_toml)
                            end

                            global experiment_id += 1
                            println("Experiment $(experiment_id) created")
                        end
                    else
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

                        # Write the updated TOML data to a new file
                        old_name = split(toml, ".")[1]
                        dir = "output_close_mixed_cr_"

                        if method == "k_means"
                            dir *= "kmn_"
                        elseif method == "k_medoids"
                            dir *= "kmd_"
                        elseif method == "convex_hull"
                            dir *= "cvx_"
                        end

                        if distance == "CosineDist"
                            dir *= "cos_"
                        elseif distance == "SqEuclidean"
                            dir *= "sq_"
                        end

                        dir *= "$(number_of_periods)"
                        dir *= "/fixed"

                        original_toml["test"]["dir"] = dir
                        original_toml["input"]["data"]["investment"] = "investment.csv"
                        original_toml["input"]["data"]["cost"] = "scalars.toml"
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
end