using CSV
using DataFrames

function rename_time_step_column(file_path::String)
    df = CSV.read(file_path, DataFrame)
    if "time_step" in names(df)
        rename!(df, :time_step => :timestep)
        CSV.write(file_path, df)
    else
        println("Column 'time_step' not found in $file_path")
    end
end

# Paths to the CSV files
demand_file = "./case_studies/stylized_EU/inputs/demand.csv"
generation_availability_file = "./case_studies/stylized_EU/inputs/generation_availability.csv"

# Rename the column in both files
rename_time_step_column(demand_file)
rename_time_step_column(generation_availability_file)