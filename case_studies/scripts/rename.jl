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

folder = "./case_studies/stylized_EU/configs_blended2"
files = readdir(folder)

for file in files
    if endswith(file, ".toml") 
        filepath = joinpath(folder, file)
        config = TOML.parsefile(filepath)
        config = keys_to_symbols(config)
        
        config[:input][:rp][:method] = "convex_hull"
        
        open(filepath, "w") do io
            TOML.print(io, config)
        end
    end
end
        