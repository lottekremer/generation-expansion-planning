using CSV
using DataFrames
using Statistics
using XLSX

# Reading the original demand data from the CSV file and calculating the average demand per country
df = CSV.read(".\\case_studies\\scripts\\scenarios_separate\\demand_0000.csv", DataFrame)
average_demand_per_country = combine(groupby(df, :location), :demand => mean => :average_demand)
println(average_demand_per_country)

# Create a dictionary to store the new demand profiles for each location
locations_demand_dict = Dict()
file = ".\\case_studies\\scripts\\demand_data\\demandprofiles_allyears.xlsx"

XLSX.openxlsx(file) do workbook
    for sheetname in XLSX.sheetnames(workbook)
        # Convert the sheet to a DataFrame, using headers as column names
        sheet = XLSX.gettable(workbook[sheetname], infer_eltypes=true)
        sheet_data = DataFrame(sheet)
        # Store the DataFrame in the dictionary with the sheet name as the key
        locations_demand_dict[sheetname] = sheet_data
    end
end

# Resize the new demand profiles based on the average demand per country from the original data
for location in average_demand_per_country.location

    all_demand_values = vec(Matrix(locations_demand_dict[location]))
    average_value_new = mean(skipmissing(all_demand_values))

    average_value_old = average_demand_per_country[average_demand_per_country.location.==location, :average_demand][1]
    factor = average_value_old / average_value_new
    println("Location: $location, Factor: $factor")
    for col in names(locations_demand_dict[location])
        if eltype(locations_demand_dict[location][!, col]) <: Number
            locations_demand_dict[location][!, col] .= locations_demand_dict[location][!, col] .* factor
        end
    end
end

# Save the results to a new XLSX file in the same format
new_file = ".\\case_studies\\scripts\\demand_data\\demandprofiles_allyears_new.xlsx"

XLSX.openxlsx(new_file, mode="w") do xf
    i = 1  # Initialize sheet counter
    for (sheetname, sheet_data) in locations_demand_dict
        if i == 1
            # For the first sheet, directly rename the first sheet in the workbook
            sheet = xf[1]  # Access the first sheet in the workbook
            XLSX.rename!(sheet, sheetname)  # Rename it to the desired sheet name
            XLSX.writetable!(sheet, sheet_data)  # Write the data
        else
            # For subsequent sheets, add new sheets
            sheet = XLSX.addsheet!(xf, sheetname)  # Add a new sheet
            XLSX.writetable!(sheet, sheet_data)  # Write the data to the new sheet
        end
        i += 1  # Increment the sheet counter
    end
end
