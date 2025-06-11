using CSV
using DataFrames
using TOML

output_folder = "./case_studies/europe/configs"
folders = readdir(output_folder)

result_in = DataFrame(rp=String[], clustering=String[], seed=Int[], num_periods=Int[],
    investment_cost=Float64[], data=String[], windon=Float64[], windoff=Float64[], solar=Float64[])

# Loop through each folder to collect the information
for folder in folders
    folder_parts = split(folder, "_")

    # Not an output folder
    if length(folder_parts) < 5
        continue
    else
        println("I'm busy in ...", folder)
        data = folder_parts[1]
        if length(folder_parts) >= 6
            i = 1
        else
            i = 0
        end
        num_periods = parse(Int, folder_parts[5+i])
        clustering = folder_parts[3+i]
        distance = folder_parts[4+i]
        rp = folder_parts[2+i]

        if rp == "cr"
            rp = "cross"
        end

        if clustering == "kmn"
            clustering = "k_means"
        elseif clustering == "kmd"
            clustering = "k_medoids"
        elseif clustering == "cvx"
            clustering = "convex_hull"
        elseif clustering == "cb"
            clustering = "conical_bounded"
        end

        if distance == "sq"
            distance = "SqEuclidean"
        end

        for seedpath in readdir(joinpath(output_folder, folder))
            if contains(seedpath, "seed")
                seed = parse(Int, split(seedpath, "_")[2])
                for subfolder in readdir(joinpath(output_folder, folder, seedpath))
                    if subfolder == "initial_run"
                        scalars_path = joinpath(output_folder, folder, seedpath, subfolder, "scalars.toml")
                        scalars = TOML.parsefile(scalars_path)
                        investment = scalars["total_investment_cost"]
                        investment_path = joinpath(output_folder, folder, seedpath, subfolder, "investment.csv")
                        investments = CSV.read(investment_path, DataFrame)

                        windon = sum(filter(row -> row.technology == "Wind_Onshore", investments).capacity)
                        windoff = sum(filter(row -> row.technology == "Wind_Offshore", investments).capacity)
                        solar = sum(filter(row -> row.technology == "Solar", investments).capacity)

                        push!(result_in, (rp, clustering, seed, num_periods, investment, data, windon, windoff, solar))
                        break
                    end
                end
            else
                if i == 1
                    seed = parse(Int, folder_parts[2])
                    if seed != 1
                        break
                    end
                else
                    seed = 0
                    break
                end

                if seedpath == "initial_run"
                    scalars_path = joinpath(output_folder, folder, seedpath, "scalars.toml")
                    scalars = TOML.parsefile(scalars_path)
                    investment = scalars["total_investment_cost"]
                    investment_path = joinpath(output_folder, folder, seedpath, "investment.csv")
                    investments = CSV.read(investment_path, DataFrame)

                    windon = sum(filter(row -> row.technology == "Wind_Onshore", investments).capacity)
                    windoff = sum(filter(row -> row.technology == "Wind_Offshore", investments).capacity)
                    solar = sum(filter(row -> row.technology == "Solar", investments).capacity)

                    push!(result_in, (rp, clustering, seed, num_periods, investment, data, windon, windoff, solar))
                    break
                end
            end
        end
    end

end

# Save the combined data to a new CSV file
CSV.write("./case_studies/europe/results/investment.csv", result_in)
println("Table with all information has been created")