export read_config, dataframe_to_dict, jump_variable_to_df, save_result, edit_config

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

    data_config[:time_frame] = length(sets_config[:time_steps])

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
        data_config[:demand][!, :rep_period] = ones(Int, size(data_config[:demand], 1))
        data_config[:generation_availability][!, :rep_period] = ones(Int, size(data_config[:generation_availability], 1))
        
        # Set period and its weights to a list with just a 1 and 1
        rp_config[:periods] = [1]
        rp_config[:period_weights] = [1.0]

        # Set periods_per_scenario to be a list of tuples with just a 1 and all scenarios
        rp_config[:periods_per_scenario] = [(1, scenario) for scenario in sets_config[:scenarios]]
    end

    config[:output][:dir] = (config_dir, config[:output][:dir]) |> joinpath |> abspath

    # make sure that the values are rounded
    data_config[:demand][!, :demand] = round.(data_config[:demand][!, :demand]; digits = 8)
    data_config[:generation_availability][!, :availability] = round.(data_config[:generation_availability][!, :availability]; digits = 8)

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
    save_dataframe(result.operational_cost_per_scenario, config[:operational_cost_per_scenario])

    scalar_data = Dict(
        "total_cost" => result.total_cost,
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
    num_periods = rp_config[:number_of_periods]

    # Create copies to not lose the old data
    config[:input][:secondStage] = Dict{Symbol, Any}()
    config[:input][:secondStage][:demand] = deepcopy(data_config[:demand])
    config[:input][:secondStage][:generation_availability] = deepcopy(data_config[:generation_availability])
    config[:input][:secondStage][:scenarios] = deepcopy(sets_config[:scenarios])
    config[:input][:secondStage][:time_steps] = deepcopy(sets_config[:time_steps])
    config[:input][:secondStage][:scenario_probabilities] = deepcopy(data_config[:scenario_probabilities])

    if rp_config[:method] == "k_means"
        method = :k_means
    elseif rp_config[:method] == "k_medoids"
        method = :k_medoids
    elseif rp_config[:method] == "convex_hull"
        method = :convex_hull
    else
        error("Invalid method specified in the configuration.")
    end

    if rp_config[:distance] == "SqEuclidean"
        distance = SqEuclidean()
    elseif rp_config[:distance] == "CosineDist"
        distance = CosineDist()
    elseif rp_config[:distance] == "CityBlock"
        distance = Cityblock()
    else
        error("Invalid distance type specified in the configuration.")
    end

    if rp_config[:clustering_type] == "completescenario"
        # Process the data to get correct format for TulipaClustering and cluster
        data, max_demand = process_data(data_config[:demand], data_config[:generation_availability], scenarios, period_duration, timesteps)
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods)

        # Add to config
        rp_config[:periods] = 1:num_periods
        rp_config[:period_weights] = weights
        data_config[:demand] = demand_res
        data_config[:generation_availability] = generation_res
    
    elseif rp_config[:clustering_type] == "perscenario"
        demand_total = DataFrame()
        generation_total = DataFrame()
        weights_total = []
        for (index, scenario) in enumerate(scenarios)
            # Process the data per scenario, representative days get sequenced numbers
            scenario_data, max_demand = process_data(data_config[:demand], data_config[:generation_availability], [scenario], period_duration, timesteps)
            scenario_rp = find_representative_periods(scenario_data, num_periods; method = method, distance = distance)
            scenario_rp.profiles[!, :rep_period] = scenario_rp.profiles[!, :rep_period] .+ (index - 1) * num_periods

            # Process results
            demand_res, generation_res, weights = process_rp(scenario_rp, max_demand, num_periods)

            # Concatenate to the total data
            if index == 1
                demand_total = deepcopy(demand_res)
                generation_total = deepcopy(generation_res)
                weights_total = deepcopy(weights)
            else
                demand_total = vcat(demand_total, demand_res)
                generation_total = vcat(generation_total, generation_res)
                weights_total = vcat(weights_total, weights)    
            end
        end
        rp_config[:periods] = 1:(num_periods * length(scenarios))
        rp_config[:period_weights] = weights_total
        data_config[:demand] = demand_total
        data_config[:generation_availability] = generation_total

    elseif rp_config[:clustering_type] == "crosscenario"
        demand_temp = DataFrame()
        generation_temp = DataFrame()
        for (index, scenario) in enumerate(scenarios)
            # Treat new scenarios as new days 
            demand_data = filter(row -> row.scenario == scenario && row.time_step in timesteps, data_config[:demand])
            demand_data[!, :time_temp] = demand_data[!, :time_step] .+ (index - 1) * data_config[:time_frame]
            generation_data = filter(row -> row.scenario == scenario && row.time_step in timesteps, data_config[:generation_availability])
            generation_data[!, :time_temp] = generation_data[!, :time_step] .+ (index - 1) * data_config[:time_frame]
            demand_temp = vcat(demand_temp, demand_data)
            generation_temp = vcat(generation_temp, generation_data)
        end

        # Rename to be able to use the original function 
        scenario_time = unique(select(demand_temp, [:scenario, :time_step, :time_temp]))
        demand_temp = select(demand_temp, Not(:time_step))
        generation_temp = select(generation_temp, Not(:time_step))
        rename!(demand_temp, :time_temp => :time_step)
        rename!(generation_temp, :time_temp => :time_step)
        timesteps = 1:maximum(demand_temp.time_step)
        scenario_time[!, :period] = Int.(floor.((scenario_time.time_temp .- 1) ./ period_duration) .+ 1)

        # Cluster based on this data and drop the scenario column
        data, max_demand = process_data(demand_temp, generation_temp, scenarios, period_duration, timesteps)
        data = select(data, Not(:scenario)) 
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods)

        # Put the sparse matrix in a dataframe for easier indexing
        row_indices, col_indices, values = findnz(rp.weight_matrix)
        weight_df = DataFrame(period = row_indices, rep_period = col_indices, weight = values)
        weight_df[!, :scenario] = scenarios[Int.(ceil.(weight_df.period ./ num_periods)).% length(scenarios) .+ 1]

        # Add scenario column with "cross" to the demand and generation data and save secondStage_config[:scenarios] = scenarios
        demand_res[!, :scenario] .= "cross"
        generation_res[!, :scenario] .= "cross"
    
        # Add to config 
        # TODO: it is now assumed that the weights are the same for each scenario, this should be changed
        rp_config[:periods] = 1:(num_periods)
        rp_config[:period_weights] = weights
        data_config[:demand] = demand_res
        data_config[:generation_availability] = generation_res
        sets_config[:scenarios] = Symbol.(["cross"])
        data_config[:scenario_probabilities] = DataFrame(scenario = Symbol.(["cross"]), probability = [1/length(scenarios)])
    else
        error("Invalid clustering type specified in the configuration.")
    end

    string_columns_demand = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:demand]))
    data_config[:demand][!, string_columns_demand] = Symbol.(data_config[:demand][!, string_columns_demand])

    string_columns_generation = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:generation_availability]))
    data_config[:generation_availability][!, string_columns_generation] = Symbol.(data_config[:generation_availability][!, string_columns_generation])

    # Set periods_per_scenario to be a list of unique tuples with all combinations of rep_period and scenario in demand
    rp_config[:periods_per_scenario] = unique(Tuple.(map(collect, zip(data_config[:demand].rep_period, data_config[:demand].scenario))))

end

function process_data(demand_data, availability_data, scenarios, period_duration, timesteps)

    # Filter the data for the chosen scenarios
    demand_data = filter(row -> row.scenario in scenarios, demand_data)
    generation_availability_data = filter(row -> row.scenario in scenarios, availability_data)

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

    return combined_data, max_demand

end

function edit_config(config::Dict{Symbol,Any}, result::ExperimentResult)    secondStage_config = config[:input][:secondStage]   

    # Set investment field
    secondStage_config[:investment] = result.investment
    secondStage_config[:total_investment_cost] = result.total_investment_cost

    # Deduce new set NG of location + generation technology
    secondStage_config[:generators] = Tuple.(map(collect, zip(result.investment.location, result.investment.technology)))
    secondStage_config[:generation_technologies] = unique([g[2] for g ∈ secondStage_config[:generators]])

    # Make sure that the values are rounded
    secondStage_config[:demand][!, :demand] = round.(secondStage_config[:demand][!, :demand]; digits = 8)
    secondStage_config[:generation_availability][!, :availability] = round.(secondStage_config[:generation_availability][!, :availability]; digits = 8)

    return config
end

function process_rp(rp, max_demand::Float64, num_periods)
    # Split demand and generation data
    split_values = split.(rp.profiles.profile_name, "_")
    rp.profiles[!, :location] = getindex.(split_values, 1)
    rp.profiles[!, :technology] = getindex.(split_values, 2)

    # Get correct demand dataframes
    demand_res = filter(row -> row.technology == "demand", rp.profiles)
    demand_res[!, :demand] = demand_res[!, :value] * max_demand
    demand_res = select(demand_res, Not([:technology, :profile_name, :value]))
    rename!(demand_res, :timestep => :time_step)

    # Get correct generation availability dataframes
    generation_res = filter(row -> row.technology != "demand", rp.profiles)
    generation_res = select(generation_res, Not(:profile_name))
    rename!(generation_res, :value => :availability)
    rename!(generation_res, :timestep => :time_step)

    # Add period weights
    weights = [sum(rp.weight_matrix[:, col]) for col in 1:num_periods]

    return demand_res, generation_res, weights
end