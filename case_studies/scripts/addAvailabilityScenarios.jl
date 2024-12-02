using CSV
using DataFrames
using Statistics
using XLSX

# Load the data for a specific landcode, per technology into a dicotionary
landcode_switch = Dict("AT00" => "AUS", "BE00" => "BEL", "GR00" => "BLK", "CH00" => "SWI", "CZ00" => "CZE", "DE00" => "GER", "DKE1" => "DEN", "EE00" => "BLT",
    "ES00" => "SPA", "FI00" => "FIN", "FR00" => "FRA", "HU00" => "SKO", "IE00" => "IRE", "ITN1" => "ITA", "NL00" => "NED", "NOS0" => "NOR", "PL00" => "POL",
    "PT00" => "POR", "SE02" => "SWE", "UK00" => "UKI")

wind_on_dict = Dict{String,DataFrame}()
wind_off_dict = Dict{String,DataFrame}()
solar_dict = Dict{String,DataFrame}()

for (old, new) in landcode_switch
    file_pattern_windoff = "./case_studies/scripts/availability_data/PECD_Wind_Offshore_2030_$(old)_edition 2023.2.csv"
    file_pattern_windon = "./case_studies/scripts/availability_data/PECD_Wind_Onshore_2030_$(old)_edition 2023.2.csv"
    file_pattern_solar = "./case_gmstudies/scripts/availability_data/PECD_LFSolarPV_2030_$(old)_edition 2023.2.csv"
    solar = CSV.read(file_pattern_solar, DataFrame; header=true)
    wind_on = CSV.read(file_pattern_windon, DataFrame; header=true)
    if isfile(file_pattern_windoff)
        wind_off = CSV.read(file_pattern_windoff, DataFrame; header=true)
    else
        years = [1982.0, 1987.0, 1992.0, 1995.0, 1997.0, 2002.0, 2008.0, 2009.0, 2012.0]
        wind_off = DataFrame([Symbol(year) => fill(0.0, 8760) for year in years]...)
    end

    for (name, data) in [("solar", solar), ("wind_on", wind_on), ("wind_off", wind_off)]
        for col in names(data)
            if occursin(r"^\d+\.\d+$", col)
                rename!(data, col => split(col, ".")[1])
            end
        end
        if name == "solar"
            solar_dict[new] = data
        elseif name == "wind_on"
            wind_on_dict[new] = data
        elseif name == "wind_off"
            wind_off_dict[new] = data
        end
    end

    println("Loaded data for $(new)...")
end

println("Loading done...")

# Create the new availability scenarios
years_of_interest = [1982, 1987, 1992, 1995, 1997, 2002, 2008, 2009, 2012]

for year in years_of_interest
    results = DataFrame(location=String[], technology=String[], time_step=Int[], availability=Float64[])

    for (location, data) in solar_dict
        for (i, availability) in enumerate(data[:, Symbol(year)])
            push!(results, (location, "SunPV", i, availability))
        end
        println("Added solar data for $(location)...")
    end

    for (location, data) in wind_on_dict
        for (i, availability) in enumerate(data[:, Symbol(year)])
            push!(results, (location, "WindOn", i, availability))
        end
        println("Added wind onshore data for $(location)...")
    end

    for (location, data) in wind_off_dict
        for (i, availability) in enumerate(data[:, Symbol(year)])
            push!(results, (location, "WindOff", i, availability))
        end
        println("Added wind offshore data for $(location)...")
    end

    output_file = "./case_studies/scripts/scenarios_separate/generation_availability_$(year).csv"
    CSV.write(output_file, results)

end