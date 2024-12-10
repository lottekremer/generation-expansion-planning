export read_config, dataframe_to_dict, jump_variable_to_df, save_result

"""
    keys_to_symbols(dict::AbstractDict{String,Any}; recursive::Bool=true)::Dict{Symbol,Any}

Create a new dictionary that is identical to `dict`, except all of the keys 
are converted from strings to
[symbols](https://docs.julialang.org/en/v1/manual/metaprogramming/#Symbols).
Symbols are [interned](https://en.wikipedia.org/wiki/String_interning) and are
faster to work with when they serve as unique identifiers.
"""
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

"""
    read_config(config_path::AbstractString)::Dict{Symbol,Any}

Parse the contents of the config file `config_path` into a dictionary. The file
must be in TOML format.
"""
function read_config(config_path::AbstractString)::Dict{Symbol,Any}
    current_dir = pwd()  # current working directory
    full_path = (current_dir, config_path) |> joinpath |> abspath  # full path to the config file

    # read config to a dictionary and change keys to symbols
    config = full_path |> TOML.parsefile |> keys_to_symbols

    # aliases for input config dictionaries 
    data_config = config[:input][:data]
    sets_config = config[:input][:sets]
    rp_config = config[:input][:rp]

    # find the input directory
    config_dir = full_path |> dirname  # directory where the config is located
    input_dir = (config_dir, "..", data_config[:dir]) |> joinpath |> abspath  # input data directory

    # read the dataframes from files
    function read_file!(path::AbstractString, key::Symbol, format::Symbol)
        if format ≡ :CSV
            data_config[key] = (path, data_config[key]) |> joinpath |> CSV.File |> DataFrame
            # If a scenario is included, make sure that they are seen as strings to be accessed as symbols later 
            if "scenario" in names(data_config[key])
                data_config[key][!, :scenario] = string.(data_config[key][!, :scenario])
                data_config[key][!, :scenario] = convert(Vector{String}, data_config[key][!, :scenario])
            end

            string_columns = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[key]))
            data_config[key][!, string_columns] = Symbol.(data_config[key][!, string_columns])

        elseif format ≡ :TOML
            data_config[key] = (path, data_config[key]) |> joinpath |> TOML.parsefile |> keys_to_symbols
        end
    end

    read_file!(input_dir, :demand, :CSV)
    read_file!(input_dir, :generation_availability, :CSV)
    read_file!(input_dir, :generation, :CSV)
    read_file!(input_dir, :transmission_lines, :CSV)
    read_file!(input_dir, :scalars, :TOML)

    # change scenario vector of strings to vector of symbols and find weights, if list is not provided then complete list is taken
    if sets_config[:scenarios] == "auto"
        sets_config[:scenarios] = ["1900", "1982", "1987", "1992", "1995", "1997", "2002", "2008", "2009", "2012"]
    end
    sets_config[:scenarios] = Symbol.(sets_config[:scenarios])

    if data_config[:scenario_probabilities] == "auto"
        probabilities = ones(length(sets_config[:scenarios])) / length(sets_config[:scenarios])
        data_config[:scenario_probabilities] = DataFrame(scenario = sets_config[:scenarios], probability = probabilities)
    else
        read_file!(input_dir, :scenario_probabilities, :CSV)
    end

    # remove the directory entry as it has been added to the file paths
    delete!(data_config, :dir)

    # resolve the sets

    if sets_config[:time_steps] == "auto"
        t_min = min(minimum(data_config[:demand].time_step), minimum(data_config[:generation_availability].time_step))
        t_max = max(maximum(data_config[:demand].time_step), maximum(data_config[:generation_availability].time_step))
        sets_config[:time_steps] = t_min:t_max
    elseif isa(sets_config[:time_steps], Int)
        sets_config[:time_steps] = 1:sets_config[:time_steps]
    end

    if sets_config[:locations] == "auto"
        sets_config[:locations] =
            data_config[:demand].location ∪
            data_config[:generation_availability].location ∪
            data_config[:generation].location ∪
            data_config[:transmission_lines].from ∪
            data_config[:transmission_lines].to
    end

    if sets_config[:generators] == "auto"
        sets_config[:generators] =
            Tuple.(map(collect, zip(data_config[:generation].location, data_config[:generation].technology)))
    end
    sets_config[:generation_technologies] = unique([g[2] for g ∈ sets_config[:generators]])

    if sets_config[:transmission_lines] == "auto"
        sets_config[:transmission_lines] =
            Tuple.(map(collect, zip(data_config[:transmission_lines].from, data_config[:transmission_lines].to)))
    end

    # create periods
    if rp_config[:use_periods]
        addPeriods!(config, rp_config[:number_of_periods])
        sets_config[:time_steps] = 1:rp_config[:period_duration]
    else
        # Set demand and generation availability to have a rep_period of 1
        data_config[:demand][!, :rep_period] = ones(size(data_config[:demand], 1))
        data_config[:generation_availability][!, :rep_period] = ones(size(data_config[:generation_availability], 1))
        
        # Set period and its weights to a list with just a 1 and 1
        rp_config[:periods] = [1]
        rp_config[:period_weights] = [1.0]
    end

    config[:output][:dir] = (config_dir, config[:output][:dir]) |> joinpath |> abspath

    return config
end

"""]
    dataframe_to_dict(
        df::AbstractDataFrame,
        keys::Union{Symbol, Vector{Symbol}},
        value::Symbol
    ) -> Dict

Convert the dataframe `df` to a dictionary using columns `keys` as keys and
`value` as values. `keys` can contain more than one column symbol, in which case
a tuple key is constructed.
"""
function dataframe_to_dict(
    df::AbstractDataFrame,
    keys::Union{Symbol,Vector{Symbol}},
    value::Symbol
)::Dict
    return if typeof(keys) <: AbstractVector
        Dict(Tuple.(eachrow(df[!, keys])) .=> Vector(df[!, value]))
    else
        Dict(Vector(df[!, keys]) .=> Vector(df[!, value]))
    end
end

"""
Returns a `DataFrame` with the values of the variables from the JuMP container
`variable`. The column names of the `DataFrame` can be specified for the
indexing columns in `dim_names`, and the name and type of the data value column
by a Symbol `value_name` (e.g., `:Value`) and a DataType `value_type`.
"""
function jump_variable_to_df(variable::AbstractArray{T,N};
    dim_names::NTuple{N,Symbol},
    value_name::Symbol=:value,
    value_type::DataType=Float64) where {T<:Union{VariableRef,AffExpr},N}

    if isempty(variable)
        return DataFrame()
    end
    values = value.(variable)
    df = DataFrame(Containers.rowtable(values), [dim_names..., value_name])
    if value_type <: Integer
        df[!, value_name] = round.(df[:, value_name])
    end
    df[!, value_name] = convert.(value_type, df[:, value_name])
    filter!(row -> row[value_name] ≠ 0.0, df)
    return df
end


function save_result(result::ExperimentResult, config::Dict{Symbol,Any})
    dir = config[:dir]
    timestamp = Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")

    dir = joinpath(dir, timestamp)
    mkpath(dir)

    function save_dataframe(df::AbstractDataFrame, file::String)
        full_path = (dir, file) |> joinpath
        CSV.write(full_path, df)
    end

    save_dataframe(result.investment, config[:investment])
    save_dataframe(result.production, config[:production])
    save_dataframe(result.line_flow, config[:line_flow])
    save_dataframe(result.loss_of_load, config[:loss_of_load])

    scalar_data = Dict(
        "total_investment_cost" => result.total_investment_cost,
        "total_operational_cost" => result.total_operational_cost,
        "runtime" => result.runtime,
    )
    fname = (dir, config[:scalars]) |> joinpath
    open(fname, "w") do io
        TOML.print(io, scalar_data)
    end
end

function addPeriods!(config::Dict{Symbol,Any}, num_periods::Int)
    data_config = config[:input][:data]
    sets_config = config[:input][:sets]
    rp_config = config[:input][:rp]
    scenarios = sets_config[:scenarios]
    period_duration = rp_config[:period_duration]
    timesteps = sets_config[:time_steps]

    # Create copies to not lose the old data
    data_config[:old_demand] = deepcopy(data_config[:demand])
    data_config[:old_generation] = deepcopy(data_config[:generation_availability])

    if rp_config[:clustering_type] == "completescenario"
        # Process the data to get correct format for TulipaClustering and cluster
        data, max_demand = process_data(data_config[:demand], data_config[:generation_availability], scenarios, period_duration, timesteps, rp_config[:clustering_type])
        rp = find_representative_periods(data, rp_config[:number_of_periods])

        # Split demand and generation data
        split_values = split.(rp.profiles.profile_name, "_")
        rp.profiles[!, :location] = getindex.(split_values, 1)
        rp.profiles[!, :technology] = getindex.(split_values, 2)

        # Get correct demand dataframes
        data_config[:demand] = filter(row -> row.technology == "demand", rp.profiles)
        data_config[:demand][!, :demand] = data_config[:demand][!, :value] * max_demand
        data_config[:demand] = select(data_config[:demand], Not([:technology, :profile_name, :value]))
        rename!(data_config[:demand], :timestep => :time_step)

        # Get correct generation availability dataframes
        data_config[:generation_availability] = filter(row -> row.technology != "demand", rp.profiles)
        data_config[:generation_availability] = select(data_config[:generation_availability], Not(:profile_name))
        rename!(data_config[:generation_availability], :value => :availability)
        rename!(data_config[:generation_availability], :timestep => :time_step)

        println("First 5 rows of generation_availability in complete scenario:")
        println(first(data_config[:generation_availability], 5))
        
        println("First 5 rows of demand in complete scenario:")
        println(first(data_config[:demand], 5))

        # Add period weights
        rp_config[:periods] = 1:num_periods
        weights = [sum(rp.weight_matrix[:, col]) for col in 1:rp_config[:number_of_periods]]
        rp_config[:period_weights] = weights
    end
    
    string_columns_demand = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:demand]))
    data_config[:demand][!, string_columns_demand] = Symbol.(data_config[:demand][!, string_columns_demand])

    string_columns_generation = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:generation_availability]))
    data_config[:generation_availability][!, string_columns_generation] = Symbol.(data_config[:generation_availability][!, string_columns_generation])

end

function process_data(demand_data, availability_data, scenarios, period_duration, timesteps, clustering_type)

    # Filter the data for the chosen scenarios
    demand_data = filter(row -> row.scenario in scenarios, demand_data)
    generation_availability_data = filter(row -> row.scenario in scenarios, availability_data)

    # TODO implement the other options
    if clustering_type == "completescenario"

        # Scale the demand data so that it is a value between 0 and 1 but store the max
        max_demand = maximum(demand_data.demand)
        demand_data.demand = demand_data.demand ./ max_demand

        # Rename to match the TulipaClustering names of :value and :timestep
        rename!(demand_data, :demand => :value)
        rename!(demand_data, :time_step => :timestep)
        rename!(generation_availability_data, :availability => :value)
        rename!(generation_availability_data, :time_step => :timestep)

        # Combine the demand and availability data into one dataframe in which profile_name is location_technology/demand, then timestep then value
        demand_data.location = string.(demand_data.location, "_demand")
        generation_availability_data.location = string.(generation_availability_data.location, "_", generation_availability_data.technology)
        generation_availability_data = select(generation_availability_data, :location, :timestep, :value, :scenario)
        combined_data = vcat(demand_data, generation_availability_data)
        rename!(combined_data, :location => :profile_name)

        # Only select timesteps in time_steps
        combined_data = filter(row -> row.timestep in timesteps, combined_data)
        
        # Split the data into periods
        split_into_periods!(combined_data; period_duration=period_duration)

    elseif rp_config[:clustering_type] == "perscenario"
        # Process data per scenario
        error("Not yet implemented")
    elseif rp_config[:clustering_type] == "crosscenario"
        error("Not yet implemented")
    else
        error("Invalid clustering type specified in the configuration.")
    end

    return combined_data, max_demand

end