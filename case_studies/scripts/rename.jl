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
    if endswith(file, ".toml") && !startswith(file, "stochastic")
        filepath = joinpath(folder, file)
        config = TOML.parsefile(filepath)
        config = keys_to_symbols(config)
        
        if config[:input][:rp][:method] == "k_means"
            # Delete file
            rm(filepath)
        end
    end
end
        