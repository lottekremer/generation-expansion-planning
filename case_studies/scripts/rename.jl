using TOML

function keys_to_symbols(
    dict::AbstractDict{String,Any};
    recursive::Bool=true
)::Dict{Symbol,Any}
    return Dict(Symbol(k) =>
        if recursive && typeof(v) <: Dict
            keys_to_symbols(v)
        else
            v
        end
                for (k, v) in dict
    )
end

folder = "./case_studies/stylized_EU/configs_experiment/configs"
files = readdir(folder)

for file in files
    if endswith(file, ".toml") && file != "stochastic.toml"
        config = TOML.parsefile(joinpath(folder, file)) |> keys_to_symbols
        if config[:input][:rp][:clustering_type] == "crosscenario"
            config[:input][:rp][:clustering_type] = "cross_scenario"
            open(joinpath(folder, file), "w") do io
                TOML.print(io, config)
            end
        elseif config[:input][:rp][:clustering_type] == "groupscenario"
            config[:input][:rp][:clustering_type] = "group_scenario"
            config[:input][:rp][:number_of_periods] = config[:input][:rp][:number_of_periods] * 10
            open(joinpath(folder, file), "w") do io
                TOML.print(io, config)
            end
        elseif config[:input][:rp][:clustering_type] == "perscenario"
            config[:input][:rp][:clustering_type] = "per_scenario"
            config[:input][:rp][:number_of_periods] = config[:input][:rp][:number_of_periods] * 10
            open(joinpath(folder, file), "w") do io
                TOML.print(io, config)
            end
        end
    end
end
        