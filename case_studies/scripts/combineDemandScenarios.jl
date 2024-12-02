using DataFrames
using XLSX

# Years that we are selecting
years_of_interest = [1982, 1987, 1992, 1995, 1997, 2002, 2008, 2009, 2012]

# Initialize two dictionaries to store the final and intermediate data
yearly_demand = Dict{Int,DataFrame}()
interim_dict = Dict{String,DataFrame}()

# Open the Excel file and iterate over each sheet
file_path = "./case_studies/scripts/demand_data/demandprofiles_allyears_new.xlsx"

XLSX.openxlsx(file_path) do workbook
    for sheetname in XLSX.sheetnames(workbook)
        # Convert the sheet to a DataFrame, using headers as column names
        sheet = XLSX.gettable(workbook[sheetname], infer_eltypes=true)
        sheet_data = DataFrame(sheet)
        # Store the DataFrame in the dictionary with the sheet name as the key
        interim_dict[sheetname] = sheet_data
    end
end

# Iterate over each country and each year to collect the demand data
for (sheetname, sheet_data) in interim_dict
    for year in years_of_interest

        if !haskey(yearly_demand, year)
            yearly_demand[year] = DataFrame(location=String[], time_step=Int[], demand=Float64[])
        end

        demands = sheet_data[!, string(year)]
        n = length(demands)
        location_names = fill(sheetname, n)
        indices = 1:n

        append!(yearly_demand[year], DataFrame(location=location_names, time_step=indices, demand=demands))
    end
end

# Save the dataframes to CSV files in the stylized_EU input folder
for (year, df) in yearly_demand
    CSV.write("./case_studies/scripts/scenarios_separate/demand_$(year).csv", df)
end