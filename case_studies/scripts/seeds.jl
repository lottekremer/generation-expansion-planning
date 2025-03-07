using Random
using JSON

# Create a dictionary with keys 1 to 100 and random seed values
seeds = Dict(i => rand(UInt32) for i in 1:100)

# Define the path to save the JSON file
file_path = "c:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/scripts/seeds.json"

# Write the dictionary to a JSON file
open(file_path, "w") do file
    JSON.print(file, seeds)
end