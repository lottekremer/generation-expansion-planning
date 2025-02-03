export read_config, dataframe_to_dict, jump_variable_to_df, save_result, edit_config, process_rp, process_data, addPeriods!

"""
    keys_to_symbols(dict::AbstractDict{String,Any}; recursive::Bool=true)::Dict{Symbol,Anye}

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

    # Read config to a dictionary and change keys to symbols
    config = full_path |> TOML.parsefile |> keys_to_symbols

    # Aliases for input config dictionaries 
    data_config = config[:input][:data]
    sets_config = config[:input][:sets]
    rp_config = config[:input][:rp]

    # Rind the input directory
    config_dir = full_path |> dirname  # directory where the config is located
    input_dir = (config_dir, "..", data_config[:dir]) |> joinpath |> abspath  # input data directory

    # Read the dataframes from files
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

    # Remove the directory entry as it has been added to the file paths
    delete!(data_config, :dir)

    # Scenarios and their probabilities 
    if sets_config[:scenarios] == "auto"
        data_config[:demand].scenario ∪ data_config[:generation_availability].scenario
    end
    sets_config[:scenarios] = Symbol.(sets_config[:scenarios])

    if data_config[:scenario_probabilities] == "auto"
        probabilities = ones(length(sets_config[:scenarios])) / length(sets_config[:scenarios])
        data_config[:scenario_probabilities] = DataFrame(scenario = sets_config[:scenarios], probability = probabilities)
    else
        read_file!(input_dir, :scenario_probabilities, :CSV)
    end
    
    # Time steps (either given as int -> 1:int, as string -> "start:end", or as "auto")
    if sets_config[:time_steps] == "auto"
        t_min = min(minimum(data_config[:demand].time_step), minimum(data_config[:generation_availability].time_step))
        t_max = max(maximum(data_config[:demand].time_step), maximum(data_config[:generation_availability].time_step))
        sets_config[:time_steps] = t_min:t_max
    elseif isa(sets_config[:time_steps], String)
        splitted = split(sets_config[:time_steps], ":")
        sets_config[:time_steps] = parse(Int, splitted[1]):parse(Int, splitted[2])
    elseif isa(sets_config[:time_steps], Int)
        sets_config[:time_steps] = 1:sets_config[:time_steps]
    end
    
    # It is necessary to save the initial length of the timesteps before creating periods
    data_config[:time_frame] = length(sets_config[:time_steps])

    # Locations, generators, generation technologies and transmission lines
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

    # Create periods
    if rp_config[:use_periods]
        addPeriods!(config) # This function creates the representative periods
    else
        # If no representative periods are used, create one large period so that the model can run as normal
        data_config[:demand][!, :rep_period] = ones(Int, size(data_config[:demand], 1))
        data_config[:generation_availability][!, :rep_period] = ones(Int, size(data_config[:generation_availability], 1))
        rp_config[:periods] = [1]
        rp_config[:period_weights] = [1.0]
        rp_config[:periods_per_scenario] = [(1, scenario) for scenario in sets_config[:scenarios]]
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
    value_type::DataType=Float64) where {T<:Union{VariableRef,AffExpr, Any},N}

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

function save_result(result::ExperimentResult, config::Dict{Symbol,Any}; fixed_investment::Bool=false)
    config_output = config[:output]
    dir = config_output[:dir]
    blended = config[:input][:rp][:blended]

    if blended
        addon = "blended"
    else
        addon = "non_blended"
    end

    if fixed_investment
        dir = joinpath(dir*"_$(addon)", "fixed")
    else
        dir = joinpath(dir*"_$(addon)", "initial_run")
    end

    mkpath(dir)

    function save_dataframe(df::AbstractDataFrame, file::String)
        full_path = (dir, file) |> joinpath
        CSV.write(full_path, df)
    end

    save_dataframe(result.investment, config_output[:investment])
    save_dataframe(result.production, config_output[:production])
    save_dataframe(result.line_flow, config_output[:line_flow])
    save_dataframe(result.loss_of_load, config_output[:loss_of_load])
    save_dataframe(result.operational_cost_per_scenario, config_output[:operational_cost_per_scenario])

    scalar_data = Dict(
        "total_cost" => result.total_cost,
        "total_investment_cost" => result.total_investment_cost,
        "total_operational_cost" => result.total_operational_cost,
        "runtime" => result.runtime,
    )
    fname = (dir, config_output[:scalars]) |> joinpath
    open(fname, "w") do io
        TOML.print(io, scalar_data)
    end
end

function addPeriods!(config::Dict{Symbol,Any})
    # Extract the necessary data from the config
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

    # Method and distance extraction
    if rp_config[:method] == "k_means"
        method = :k_means
    elseif rp_config[:method] == "k_medoids"
        method = :k_medoids
    elseif rp_config[:method] == "convex_hull"
        method = :convex_hull
    elseif rp_config[:method] == "conical_bounded"
        method = :convex_hull_with_null
    elseif rp_config[:method] == "conical_unbounded"
        method = :conical_hull
    else
        error("Invalid method specified in the config.")
    end

    if rp_config[:distance] == "SqEuclidean"
        distance = SqEuclidean()
    elseif rp_config[:distance] == "CosineDist"
        distance = CosineDist()
    elseif rp_config[:distance] == "CityBlock"
        distance = Cityblock()
    else
        error("Invalid distance type specified in the config.")
    end

    # Per clustering type, different actions are taken

    if rp_config[:clustering_type] == "group_scenario"

        # Demand and generation availability get concatenated, demand is scaled, timesteps are divided into periods
        data, max_demand = process_data(data_config[:demand], data_config[:generation_availability], scenarios, period_duration, timesteps)

        # For each day, all scenarios are concatenated, so the number of periods is divided by the number of scenarios to make it comparable to the other methods
        num_periods = floor(Int,num_periods / length(scenarios))

        # Find representative periods and process the results
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods, rp_config)
        rp_config[:periods] = 1:num_periods
        rp_config[:period_weights] = weights
        data_config[:demand] = demand_res
        data_config[:generation_availability] = generation_res
    
    elseif rp_config[:clustering_type] == "per_scenario"

        # Number of periods per scenario is found by dividing the number of periods by the number of scenarios
        num_periods = floor(Int,num_periods / length(scenarios))
        demand_total = DataFrame()
        generation_total = DataFrame()
        weights_total = []

        # Each scenario is processed separately, and the resulting representative days are concatenated
        for (index, scenario) in enumerate(scenarios)

            # Process the data per scenario, find representative days and number them sequentially
            scenario_data, max_demand = process_data(data_config[:demand], data_config[:generation_availability], [scenario], period_duration, timesteps)
            scenario_rp = find_representative_periods(scenario_data, num_periods; method = method, distance = distance)
            scenario_rp.profiles[!, :rep_period] = scenario_rp.profiles[!, :rep_period] .+ (index - 1) * num_periods
            demand_res, generation_res, weights = process_rp(scenario_rp, max_demand, num_periods, rp_config)

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

    elseif rp_config[:clustering_type] == "cross_scenario" 

        # To create a cross scenario clustering, each scenario is treated as a new set of days, so all data is concatenated and the time_step is adjusted
        demand_temp = DataFrame()
        generation_temp = DataFrame()

        for (index, scenario) in enumerate(scenarios)
            demand_data = filter(row -> row.scenario == scenario && row.time_step in timesteps, data_config[:demand])
            demand_data[!, :time_temp] = ((demand_data[!, :time_step] .- 1)  .% length(timesteps)) .+ 1 .+ (index - 1) * data_config[:time_frame]
            generation_data = filter(row -> row.scenario == scenario && row.time_step in timesteps, data_config[:generation_availability])
            generation_data[!, :time_temp] = ((generation_data[!, :time_step] .-1) .% length(timesteps)) .+1 .+ (index - 1) * data_config[:time_frame]
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

        # Cluster based on this data and drop the scenario column as it is not needed
        data, max_demand = process_data(demand_temp, generation_temp, scenarios, period_duration, timesteps)
        data = select(data, Not(:scenario)) 
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods, rp_config)

        # Add scenario column with "cross" to the demand and generation data as actual scenario is not needed in model
        demand_res[!, :scenario] .= "cross"
        generation_res[!, :scenario] .= "cross"
    
        # Add to config 
        rp_config[:periods] = 1:(num_periods)
        rp_config[:period_weights] = weights
        data_config[:demand] = demand_res
        data_config[:generation_availability] = generation_res
        sets_config[:scenarios] = Symbol.(["cross"])

        # To get correct scaling in the objective, the probabilities of scenario is kept at 1/length(original scenarios)
        data_config[:scenario_probabilities] = DataFrame(scenario = Symbol.(["cross"]), probability = [1/length(scenarios)])
    else
        error("Invalid clustering type specified in the configuration.")
    end

    # Make sure that columns are still symbols
    string_columns_demand = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:demand]))
    data_config[:demand][!, string_columns_demand] = Symbol.(data_config[:demand][!, string_columns_demand])
    string_columns_generation = findall(col -> eltype(col) <: AbstractString, eachcol(data_config[:generation_availability]))
    data_config[:generation_availability][!, string_columns_generation] = Symbol.(data_config[:generation_availability][!, string_columns_generation])

    # Set periods_per_scenario to be a list of unique tuples with all combinations of rep_period and scenario in demand and correct the time_steps to be the periods length
    rp_config[:periods_per_scenario] = unique(Tuple.(map(collect, zip(data_config[:demand].rep_period, data_config[:demand].scenario))))
    sets_config[:time_steps] = 1:rp_config[:period_duration]

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
    demand_data = select(demand_data, :location, :timestep, :value, :scenario)
    combined_data = vcat(demand_data, generation_availability_data)
    rename!(combined_data, :location => :profile_name)

    # Only select timesteps in time_steps and adjust the timesteps to start at 1
    combined_data = filter(row -> row.timestep in timesteps, combined_data)
    combined_data.timestep = combined_data.timestep .-  minimum(combined_data.timestep) .+ 1
    
    # Split the data into periods using function from TulipaClustering
    split_into_periods!(combined_data; period_duration=period_duration)
    
    return combined_data, max_demand
end

function edit_config(config::Dict{Symbol,Any}, result::ExperimentResult)
    secondStage_config = config[:input][:secondStage]   

    # Set investment field
    secondStage_config[:investment] = result.investment
    secondStage_config[:total_investment_cost] = result.total_investment_cost

    # Deduce new set NG of location + generation technology
    secondStage_config[:generators] = Tuple.(map(collect, zip(result.investment.location, result.investment.technology)))
    secondStage_config[:generation_technologies] = unique([g[2] for g ∈ secondStage_config[:generators]])

    return config
end

function process_rp(rp, max_demand, num_periods, config)

    # If blended, print the old weights and then fit the new weights, to check whether fitting works
    if config[:blended]
        lr = config[:learning_rate]
        iter = config[:max_iter]
        tolerance = config[:tol]
        if config[:method] == :conical_hull
            weight_type = :conical
        elseif config[:method] == :convex_hull_with_null
            weight_type = :conical_bounded
        else
            weight_type = :convex
        end
        println("Old weights: ", [sum(rp.weight_matrix[:, col]) for col in 1:num_periods])
        fit_rep_period_weights!(rp; weight_type = :convex, tol = tolerance, learning_rate = lr, niters = iter, adaptive_grad = false)
        println("Weights: ", [sum(rp.weight_matrix[:, col]) for col in 1:num_periods])
    end

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