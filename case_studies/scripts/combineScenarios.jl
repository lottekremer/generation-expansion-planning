using CSV
using DataFrames

# Function to combine CSV files for a given type (demand or generation_availability)
function combine_scenarios(file_type::String, scenarios::Vector{String}, output_file::String)
    combined_df = DataFrame()

    for scenario in scenarios
        file_name = "./case_studies/scripts/scenarios_separate/$(file_type)_$(scenario).csv"
        df = CSV.read(file_name, DataFrame)
        df[!, :scenario] .= scenario
        cols = names(df)
        println(cols)
        combined_df = vcat(combined_df, df)
    end

    CSV.write(output_file, combined_df)
end

scenarios = ["1900", "1982", "1987", "1992", "1995", "1997", "2002", "2008", "2009", "2012"]

# Combine demand files
combine_scenarios("demand", scenarios, "./case_studies/stylized_EU/inputs/demand.csv")

# Combine generation availability files
combine_scenarios("generation_availability", scenarios, "./case_studies/stylized_EU/inputs/generation_availability.csv")