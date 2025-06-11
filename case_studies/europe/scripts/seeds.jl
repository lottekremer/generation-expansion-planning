using Random
using JSON

Random.seed!(1234)  # Set a random seed for reproducibility

# Create 10 different seed combinations
seed_combinations = [Dict(i => rand(UInt32) for i in [100, 200, 400, 800, 1600]) for _ in 1:10]

# Save each seed combination in a separate file
for (index, seeds) in enumerate(seed_combinations)
    file_path = "c:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/inputs/seeds$(index).json"
    open(file_path, "w") do file
        JSON.print(file, seeds)
    end
end
