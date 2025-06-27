using CSV
using DataFrames

# Load the first CSV file
new = CSV.read("./case_studies/europe/results/cross_new.csv", DataFrame)
old = CSV.read("./case_studies/europe/results/total.csv", DataFrame)

# Filter old
old_per = filter(row -> (row[:type] == "initial" || row[:type] == "insample")
                            && row[:rp] == "per" && row[:num_periods] <= 200, old)
old_cross = filter(row -> (row[:type] == "initial" || row[:type] == "insample") && row[:data] == "output"
                              && row[:rp] == "cross" && row[:num_periods] <= 200, old)

combined = vcat(old_per, old_cross, new)

# Save the altered DataFrames back to CSV
CSV.write("./case_studies/europe/results/total_new.csv", combined)