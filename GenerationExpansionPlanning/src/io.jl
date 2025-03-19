export read_config, dataframe_to_dict, jump_variable_to_df, save_result, process_rp, process_data, create_representative_periods, add_fixed_investment

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

    # Rind the input directory
    config_dir = full_path |> dirname  # directory where the config is located
    input_dir = (config_dir, "..", data_config[:dir]) |> joinpath |> abspath  # input data directory

    # Remove the directory entry as it has been added to the file paths
    delete!(data_config, :dir)


    # Read the dataframes from files
    function read_file!(path::AbstractString, key::Symbol, format::Symbol)
        if format ≡ :CSV
            data_config[key] = (path, data_config[key]) |> joinpath |> CSV.File |> DataFrame

            # If a scenario is included, make sure that they are seen as strings to be accessed as symbols later 
            if "scenario" in names(data_config[key])
                data_config[key][!, :scenario] = convert(Vector{String}, string.(data_config[key][!, :scenario]))
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

    # Check if seeds field exists in config and add the dictionary of seeds
    if haskey(data_config, :seed) 
        seed_file = (input_dir, data_config[:seed]) |> joinpath |> abspath
        data_config[:seed] = JSON.parsefile(seed_file)
    end
    
    # Scenarios
    if sets_config[:scenarios] == "auto"
        sets_config[:scenarios] = data_config[:demand].scenario ∪ data_config[:generation_availability].scenario
    else
        sets_config[:scenarios] = Symbol.(sets_config[:scenarios])
        # Process data to only include the scenarios that are in the sets
        data_config[:demand] = filter(row -> row.scenario in sets_config[:scenarios], data_config[:demand])
        data_config[:generation_availability] = filter(row -> row.scenario in sets_config[:scenarios], data_config[:generation_availability])
    end

    # Scenario probabilities
    if data_config[:scenario_probabilities] == "auto"
        probabilities = ones(length(sets_config[:scenarios])) / length(sets_config[:scenarios])
        data_config[:scenario_probabilities] = DataFrame(scenario = sets_config[:scenarios], probability = probabilities)
    else
        data_config[:scenario_probabilities] = DataFrame(scenario = sets_config[:scenarios], probability = data_config[:scenario_probabilities])
    end
    
    # Periods, first check if they are already created in the dataframes
    if :period ∉ names(data_config[:demand])
        split_into_periods!(data_config[:demand], period_duration = sets_config[:period_duration])
    end
    
    if :period ∉ names(data_config[:generation_availability])
        split_into_periods!(data_config[:generation_availability], period_duration = sets_config[:period_duration])
    end

    if sets_config[:periods] == "auto"
        p_min = min(minimum(data_config[:demand].period), minimum(data_config[:generation_availability].period))
        p_max = max(maximum(data_config[:demand].period), maximum(data_config[:generation_availability].period))

        if p_min != 0
            data_config[:demand].period = data_config[:demand].period .- (p_min-1)
            data_config[:generation_availability].period = data_config[:generation_availability].period .- (p_min-1)
        end

        sets_config[:periods] = 1:(p_max - p_min + 1)

    elseif isa(sets_config[:periods], String)
        splitted = split(sets_config[:periods], ":")
        p_min = parse(Int, splitted[1])
        p_max = parse(Int, splitted[2])

        # Ensure periods are within the specified range
        valid_periods = p_min:p_max
        data_config[:demand] = filter(row -> row.period in valid_periods, data_config[:demand])
        data_config[:generation_availability] = filter(row -> row.period in valid_periods, data_config[:generation_availability])

        # Adjust the periods to start at 1
        if p_min != 0
            data_config[:demand].period = data_config[:demand].period .- (p_min-1)
            data_config[:generation_availability].period = data_config[:generation_availability].period .- (p_min-1)
        end

        sets_config[:periods] = 1:(p_max - p_min + 1)

    elseif isa(sets_config[:periods], Int)
        sets_config[:periods] = 1:sets_config[:periods]
        
        # Ensure periods are within the specified range
        data_config[:demand] = filter(row -> row.period in sets_config[:periods], data_config[:demand])
        data_config[:generation_availability] = filter(row -> row.period in sets_config[:periods], data_config[:generation_availability])
    end

    # Time steps have to be set to period duration
    sets_config[:time_steps] = 1:sets_config[:period_duration]

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
    if value != :capacity
        df[!, value] = round.(df[!, value], digits=6)
    end
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

function save_result(result::ExperimentResult, config::Dict{Symbol,Any}, time::Float64; fixed_investment::Bool=false)
    config_output = config[:output]
    dir = config_output[:dir]

    if haskey(config[:input],:rp) && config[:input][:rp][:use_periods]

        dir = add_to_name(dir, config)

        # Add the fixed investment information for the second run
        config[:input][:fixed] = Dict()
        config[:input][:fixed][:investment] = result.investment
        config[:input][:fixed][:total_investment_cost] = result.total_investment_cost
        config[:input][:fixed][:generators] = Tuple.(map(collect, zip(config[:input][:fixed][:investment].location, config[:input][:fixed][:investment].technology)))
        config[:input][:fixed][:generation_technologies] = unique([g[2] for g ∈ config[:input][:fixed][:generators]])

        # See if it is first or second run
        if !fixed_investment
            dir = joinpath(dir, "initial_run")
        else
            dir = joinpath(dir, "fixed")
        end

    elseif haskey(config[:input],:rp) && haskey(config[:input], :fixed) && config[:input][:fixed][:fixed_run]
        dir = config[:input][:fixed][:dir]
        dir = joinpath(dir, "..", "test")
        print(dir)

    else
        dir = joinpath(dir, "initial_run")
    end

    mkpath(dir)

    function save_dataframe(df::AbstractDataFrame, file::String)
        float_columns = findall(col -> eltype(col) <: AbstractFloat, eachcol(df))
        df[!, float_columns] = round.(df[!, float_columns], digits=6)
        full_path = (dir, file) |> joinpath
        CSV.write(full_path, df)
    end

    save_dataframe(result.investment, config_output[:investment])
    save_dataframe(result.production, config_output[:production])
    save_dataframe(result.line_flow, config_output[:line_flow])
    save_dataframe(result.loss_of_load, config_output[:loss_of_load])
    save_dataframe(result.operational_cost_per_scenario, config_output[:operational_cost_per_scenario])

    scalar_data = Dict(
        "total_cost" => round(result.total_cost, sigdigits=6),
        "total_investment_cost" => round(result.total_investment_cost, sigdigits=6),
        "total_operational_cost" => round(result.total_operational_cost, sigdigits=6),
        "runtime" => result.runtime,
        "process_time" => time
    )

    fname = (dir, config_output[:scalars]) |> joinpath
    open(fname, "w") do io
        TOML.print(io, scalar_data)
    end
end

function create_representative_periods(config::Dict{Symbol,Any})::Dict{Symbol,Any}
    # Configs
    data_config = config[:input][:data]
    sets_config = config[:input][:sets]
    rp_config = config[:input][:rp]

    # Parameters that will be reused a lot
    period_duration = sets_config[:period_duration]
    num_periods = rp_config[:number_of_periods]
    scenarios = sets_config[:scenarios]

    # Method extraction
    if rp_config[:method] == "k_means"
        method = :k_means
        Random.seed!(data_config[:seed][string(num_periods)])
    elseif rp_config[:method] == "k_medoids"
        method = :k_medoids
        Random.seed!(data_config[:seed][string(num_periods)])
    elseif rp_config[:method] == "convex_hull"
        method = :convex_hull
    elseif rp_config[:method] == "conical_bounded"
        method = :convex_hull_with_null
    elseif rp_config[:method] == "conical_unbounded"
        method = :conical_hull
    else
        error("Invalid method specified in the config.")
    end

    # Distance extraction
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

        # Demand and generation availability get concatenated and normalized
        data, max_demand = process_data(copy(data_config[:demand]), copy(data_config[:generation_availability]))

        # For each day, all scenarios are concatenated, so the number of periods is divided by the number of scenarios to make it comparable to the other methods
        num_periods = floor(Int,num_periods / length(scenarios))

        # Find representative periods and process the results
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods, config)

        # Save the necessary information
        rp_config[:rep_periods] = 1:num_periods
        rp_config[:weights] = weights
        rp_config[:demand] = demand_res
        rp_config[:generation_availability] = generation_res
        rp_config[:scenarios] = scenarios
        rp_config[:scenario_probabilities] = data_config[:scenario_probabilities]

        rp_config[:annualization] = 8760 / (length(sets_config[:time_steps]) * length(sets_config[:periods]))


    
    elseif rp_config[:clustering_type] == "per_scenario"

        # Number of periods per scenario is found by dividing the number of periods by the number of scenarios
        num_periods = floor(Int, num_periods / length(scenarios))
        demand_total = DataFrame()
        generation_total = DataFrame()
        weights_total = Vector{Float64}()

        # Each scenario is processed separately, and the resulting representative days are concatenated
        for (index, scenario) in enumerate(scenarios)

            # Process the data per scenario, find representative days and number them sequentially
            scenario_demand = filter(row -> row.scenario == scenario, data_config[:demand])
            scenario_generation = filter(row -> row.scenario == scenario, data_config[:generation_availability])

            scenario_data, max_demand = process_data(scenario_demand, scenario_generation)
            scenario_rp = find_representative_periods(scenario_data, num_periods; method = method, distance = distance)
            scenario_rp.profiles[!, :rep_period] = scenario_rp.profiles[!, :rep_period] .+ (index - 1) * num_periods
            demand_res, generation_res, weights = process_rp(scenario_rp, max_demand, num_periods, config)

            # Concatenate to the total data
            append!(demand_total, demand_res)
            append!(generation_total, generation_res)
            append!(weights_total, weights)
        end

        # Save the necessary information
        rp_config[:rep_periods] = 1:(num_periods * length(scenarios))
        rp_config[:weights] = weights_total
        rp_config[:demand] = demand_total
        rp_config[:generation_availability] = generation_total
        rp_config[:scenarios] = scenarios
        rp_config[:scenario_probabilities] = data_config[:scenario_probabilities]

        rp_config[:annualization] = 8760 / (length(sets_config[:time_steps]) * length(sets_config[:periods]))

    elseif rp_config[:clustering_type] == "cross_scenario" 

        # To create a cross scenario clustering, each scenario is treated as a new set of days, so all data is concatenated and the period is adjusted
        demand_temp = copy(data_config[:demand])
        generation_temp = copy(data_config[:generation_availability])

        for (index, scenario) in enumerate(scenarios)
            demand_temp[demand_temp.scenario .== scenario, :period] .+= (index - 1) * length(sets_config[:periods])
            generation_temp[generation_temp.scenario .== scenario, :period] .+= (index - 1) * length(sets_config[:periods])
        end

        demand_temp[!, :scenario] .= Symbol.(["cross"])
        generation_temp[!, :scenario] .= Symbol.(["cross"])

        # Manually add lower evenlope of periods
        artificial_demand, artificial_generation = find_lower_envelope(demand_temp, generation_temp)

        # Cluster based on this data and name scenario column "cross"
        data, max_demand = process_data(demand_temp, generation_temp)
        rp = find_representative_periods(data, num_periods; method = method, distance = distance)
        demand_res, generation_res, weights = process_rp(rp, max_demand, num_periods, config; artificial_demand, artificial_generation)

        # Add to config 
        rp_config[:rep_periods] = 1:(maximum(demand_res.rep_period))
        rp_config[:weights] = weights
        rp_config[:demand] = demand_res
        rp_config[:generation_availability] = generation_res
        rp_config[:scenarios] = Symbol.(["cross"])
        rp_config[:scenario_probabilities] = DataFrame(scenario = Symbol.(["cross"]), probability = [1.0])    
        rp_config[:annualization] = 8760 / (length(sets_config[:time_steps]) * sum(weights))

    else
        error("Invalid clustering type specified in the configuration.")
    end

    # Make sure that columns are still symbols
    string_columns_demand = findall(col -> eltype(col) <: AbstractString, eachcol(rp_config[:demand]))
    rp_config[:demand][!, string_columns_demand] = Symbol.(rp_config[:demand][!, string_columns_demand])
    string_columns_generation = findall(col -> eltype(col) <: AbstractString, eachcol(rp_config[:generation_availability]))
    rp_config[:generation_availability][!, string_columns_generation] = Symbol.(rp_config[:generation_availability][!, string_columns_generation])

    # Set periods_per_scenario to be a list of unique tuples with all combinations of rep_period and scenario in demand and correct the time_steps to be the periods length
    rp_config[:rep_periods_per_scenario] = unique(Tuple.(map(collect, zip(rp_config[:demand].rep_period, rp_config[:demand].scenario))))
    return config
end

function process_data(demand_data::AbstractDataFrame, generation_availability_data::AbstractDataFrame)::Tuple{DataFrame, DataFrame}

    # Scale the demand data so that it is a value between 0 and 1 but store the max, do this per location in demand
    max_demand = combine(groupby(demand_data, :location), :demand => maximum => :max_demand)
    max_demand_dict = Dict(row.location => row.max_demand for row in eachrow(max_demand))
    demand_data[!, :demand] .= demand_data.demand ./ getindex.(Ref(max_demand_dict), demand_data.location)

    # Scale generation availability data to A / D where D is the scaled demand
    generation_availability_data = leftjoin(generation_availability_data, demand_data, 
                                        on=[:location, :period, :timestep, :scenario])
    generation_availability_data[!, :availability] .= generation_availability_data.availability ./ generation_availability_data.demand
    select!(generation_availability_data, Not(:demand))

    # Combine the demand and availability data into one dataframe in which profile_name is location_technology/demand, then timestep then value
    demand_data[!, :profile_name] = string.(demand_data.location, "_demand")
    generation_availability_data[!, :profile_name] = string.(generation_availability_data.location, "_", generation_availability_data.technology)

    # Preallocate combined_data DataFrame
    combined_data = DataFrame(
        profile_name = String[],
        timestep = Int[],
        period = Int[],
        value = Float64[],
        scenario = Symbol[]
    )

    # Append demand_data to combined_data
    append!(combined_data, DataFrame(
        profile_name = demand_data.profile_name,
        timestep = demand_data.timestep,
        period = demand_data.period,
        value = demand_data.demand,
        scenario = demand_data.scenario
    ))

    # Append generation_availability_data to combined_data
    append!(combined_data, DataFrame(
        profile_name = generation_availability_data.profile_name,
        timestep = generation_availability_data.timestep,
        period = generation_availability_data.period,
        value = generation_availability_data.availability,
        scenario = generation_availability_data.scenario
    ))
            
    return combined_data, max_demand
end

function process_rp(rp::TulipaClustering.ClusteringResult, max_demand::DataFrame, num_periods::Int, 
    config::Dict{Symbol,Any}; artificial_demand::DataFrame=DataFrame(), artificial_generation::DataFrame=DataFrame())::Tuple{DataFrame, DataFrame, Vector{Float64}}

    rp_config = config[:input][:rp]
    sets_config = config[:input][:sets]
    data_config = config[:input][:data]

    # If blended, we adjust the weights, this is currently not used in experiments
    if rp_config[:blended]
        lr = rp_config[:learning_rate]
        iter = rp_config[:max_iter]
        tolerance = rp_config[:tol]
        if rp_config[:method] == :conical_hull
            weight_type = :conical
        elseif rp_config[:method] == :convex_hull_with_null
            weight_type = :conical_bounded
        else
            weight_type = :convex
        end

        fit_rep_period_weights!(rp; weight_type = weight_type, tol = tolerance, learning_rate = lr, niters = iter, adaptive_grad = false)
    end

    # If we asked for a convex hull, calculate how many points are inside the hull
    # if rp_config[:method] == "convex_hull"
    #     ratio = calculate_convex_hull(rp)
    # end

    # Split demand and generation data
    split_values = split.(rp.profiles.profile_name, "_")
    rp.profiles[!, :location] = getindex.(split_values, 1)
    rp.profiles[!, :technology] = getindex.(split_values, 2)

    # Get correct demand dataframes
    demand_res = filter(row -> row.technology == "demand", rp.profiles)
    generation_res = filter(row -> row.technology != "demand", rp.profiles)
    rename!(demand_res, :value => :demand)
    rename!(generation_res, :value => :availability)
    demand_res = select(demand_res, Not([:technology, :profile_name]))
    
    # Get symbols
    string_columns_demand_res = findall(col -> eltype(col) <: AbstractString, eachcol(demand_res))
    string_columns_availability_res = findall(col -> eltype(col) <: AbstractString, eachcol(generation_res))
    demand_res[!, string_columns_demand_res] = Symbol.(demand_res[!, string_columns_demand_res])
    generation_res[!, string_columns_availability_res] = Symbol.(generation_res[!, string_columns_availability_res])

    # Create a demand lookup table (excluding unnecessary columns early for efficiency)
    generation_res = leftjoin(generation_res, demand_res, on=[:rep_period, :location, :timestep, :scenario])
    generation_res[!, :availability] .*= generation_res.demand
    select!(generation_res, Not([:demand, :profile_name]))
    
    # Efficiently assign max_demand values based on location (avoiding per-row loops)
    demand_res = leftjoin(demand_res, max_demand, on=:location)
    demand_res[!, :demand] .*= demand_res.max_demand
    select!(demand_res, Not(:max_demand))

    # Add period weights
    total_periods = length(sets_config[:periods])
    if rp_config[:clustering_type] == "cross_scenario"
        start = 1
        finish = total_periods
        unique_scenarios = sets_config[:scenarios]
        scenario_prob = data_config[:scenario_probabilities]

        for s in unique_scenarios
            row_index = findfirst(row -> row == s, scenario_prob.scenario)
            rp.weight_matrix[start:finish, :] *= scenario_prob[row_index, :probability]
            start += total_periods
            finish += total_periods
        end

        weights = [sum(rp.weight_matrix[:, col]) for col in 1:num_periods]
        total_weights = sum(weights)
        weights = weights ./ (total_weights / total_periods)

    else
        weights = [sum(rp.weight_matrix[:, col]) for col in 1:num_periods]

        # If weigths are not convex, normalize them
        total_weights = sum(weights)
        weights = weights ./ (total_weights / total_periods)
    end

    # Add artificial periods if they exist
    if !isempty(artificial_demand)
        # Rename
        rename!(artificial_demand, :period => :rep_period)
        rename!(artificial_generation, :period => :rep_period)

        # Get correct rep_period
        artificial_demand[!, :rep_period] .+= maximum(demand_res.rep_period)
        artificial_generation[!, :rep_period] .+= maximum(generation_res.rep_period)
        append!(demand_res, artificial_demand)
        append!(generation_res, artificial_generation)
        append!(weights, 1.0)
        # append!(weights, 1.0)
        # append!(weights, 1.0)
        # append!(weights, 1.0)
    end

    return demand_res, generation_res, weights
end

function add_fixed_investment(config::Dict{Symbol,Any})::Dict{Symbol,Any}
    fixed = config[:input][:fixed]
    dir = fixed[:dir]
    current_dir = pwd()
    full_path = joinpath(current_dir, dir)

    fixed[:investment] = (full_path, fixed[:investment]) |> joinpath |> CSV.File |> DataFrame
    string_columns = findall(col -> eltype(col) <: AbstractString, eachcol(fixed[:investment]))
    fixed[:investment][!, string_columns] = Symbol.(fixed[:investment][!, string_columns])

    fixed[:total_investment_cost] = (full_path, fixed[:total_investment_cost] )|> joinpath |> TOML.parsefile |> keys_to_symbols
    fixed[:total_investment_cost] = fixed[:total_investment_cost][:total_investment_cost]

    fixed[:generators] = Tuple.(map(collect, zip(fixed[:investment].location, fixed[:investment].technology)))
    fixed[:generation_technologies] = unique([g[2] for g ∈ fixed[:generators]])
    return config
end

function add_to_name(dir::String, config::Dict{Symbol, Any})::String
    rp_config = config[:input][:rp]
    data_config = config[:input][:data]

    if rp_config[:clustering_type] == "cross_scenario"
        addon = "cr_"
    elseif rp_config[:clustering_type] == "per_scenario"
        addon = "per_"
    elseif rp_config[:clustering_type] == "group_scenario"
        addon = "gr_"
    else
        addon = ""
    end

    if rp_config[:method] == "k_means"
        addon *= "kmn_"
    elseif rp_config[:method] == "k_medoids"
        addon *= "kmd_"
    elseif rp_config[:method] == "convex_hull"
        addon *= "cvx_"
    end

    if rp_config[:distance] == "SqEuclidean"
        addon *= "sq_"
    elseif rp_config[:distance] == "CosineDist"
        addon *= "cos_"
    elseif rp_config[:distance] == "CityBlock"
        addon *= "cb_"
    end
    
    addon *= string(rp_config[:number_of_periods])
    
    if haskey(data_config, :seed)
        addon *= "/seed_$(data_config[:seed][string(rp_config[:number_of_periods])])"
    end

    dir *= addon

    return dir
end

function find_lower_envelope(demand::DataFrame, generation::DataFrame)::Tuple{DataFrame, DataFrame}
    # For each generation technology, we construct a lower envelope which becomes a new period (each of the the time steps)\
    generation_new = DataFrame()
    demand_new = DataFrame()

    for timestep in unique(generation.timestep)
        for location in unique(generation.location)
            max_demand = maximum(filter(row -> row.location == location && row.timestep == timestep, demand).demand)
            
            for tech in unique(generation.technology)
                tech_data = filter(row -> row.technology == tech && row.timestep == timestep && row.location == location, generation)
                demand_data = filter(row -> row.location == location && row.timestep == timestep, demand)
                
                # Sort both datasets based on `period`
                sorted_tech_data = sort(tech_data, :period)
                sorted_demand_data = sort(demand_data, :period)

                # Ensure the periods match before dividing
                if sorted_tech_data.period == sorted_demand_data.period
                    min_ratio = minimum(sorted_tech_data.availability ./ sorted_demand_data.demand)
                else
                    error("Periods do not match between tech_data and demand_data after sorting.")
                end

                min_availability = min_ratio * max_demand

                new_row = DataFrame(location = location, period = 1, timestep = timestep, technology = tech, availability = min_availability, scenario = Symbol("cross"))
                append!(generation_new, new_row)
            end
            append!(demand_new, DataFrame(location = location, period = 1, timestep = timestep, demand = max_demand, scenario = Symbol("cross")))
        end
    end

    return demand_new, generation_new
end

# function find_lower_envelope(demand::DataFrame, generation::DataFrame)::Tuple{DataFrame, DataFrame}
#     # For each generation technology, we construct a lower envelope which becomes a new period (each of the the time steps)\
#     generation_new = DataFrame()
#     demand_new = DataFrame()

#     global counter = 0

#     for tech in unique(generation.technology)
#         global counter += 1
#         for timestep in unique(generation.timestep)
#             for location in unique(generation.location)
#                 tech_data = filter(row -> row.technology == tech && row.timestep == timestep && row.location == location, generation)
#                 min_availability = minimum(tech_data.availability)
#                 min_period = tech_data[tech_data.availability .== min_availability, :period][1]
#                 for other_tech in unique(generation.technology)
#                     if other_tech != tech
#                         min_other_availability = filter(row -> row.technology == other_tech && row.timestep == timestep && row.location == location && row.period == min_period, generation).availability[1]
#                         new_row = DataFrame(location = location, period = counter, timestep = timestep, technology = other_tech, availability = min_other_availability, scenario = Symbol("cross"))
#                         append!(generation_new, new_row)
#                     end
#                 end
#                 min_demand = filter(row -> row.location == location && row.timestep == timestep && row.period == min_period, demand).demand[1]
#                 new_row = DataFrame(location = location, period = counter, timestep = timestep, demand = min_demand, scenario = Symbol("cross"))
#                 append!(demand_new, new_row)

#                 new_row = DataFrame(location = location, period = counter, timestep = timestep, technology = tech, availability = min_availability, scenario = Symbol("cross"))
#                 append!(generation_new, new_row)
#             end
#         end
#     end

#     # For each location and timestep, find the highest demand and add it as a new period
#     for location in unique(demand.location)
#         for timestep in unique(demand.timestep)
#             max_demand = maximum(filter(row -> row.location == location && row.timestep == timestep, demand).demand)
#             max_period = filter(row -> row.location == location && row.timestep == timestep && row.demand == max_demand, demand).period[1]
            
#             new_row = DataFrame(location = location, period = counter + 1, timestep = timestep, demand = max_demand, scenario = Symbol("cross"))
#             append!(demand_new, new_row)
            
#             for tech in unique(generation.technology)
#                 max_availability = filter(row -> row.location == location && row.timestep == timestep && row.period == max_period && row.technology == tech, generation).availability[1]
#                 new_row = DataFrame(location = location, period = counter + 1, timestep = timestep, technology = tech, availability = max_availability, scenario = Symbol("cross"))
#                 append!(generation_new, new_row)
#             end
#         end
#     end

#     return demand_new, generation_new
# end

function calculate_convex_hull(rp::TulipaClustering.ClusteringResult)::Float64
    hull_points = rp.rp_matrix
    all_points = rp.clustering_matrix
    ratio = 0   
    for i in axes(all_points, 2)
        if in_hull(hull_points, all_points[:, i])
            ratio += 1
        end
    end
    ratio /= size(all_points, 1)
    return ratio
end


function in_hull(points::Matrix{Float64}, x::AbstractArray)::Bool
    n_points = size(points, 2)
    n_dim = length(x)

    # Set up the linear program
    model = Model(Gurobi.Optimizer)
    set_silent(model)  

    @variable(model, λ[1:n_points] >= 0)
    
    for i in 1:n_dim
        @constraint(model, sum(points[i, j] * λ[j] for j in 1:n_points) == x[i])
    end

    @constraint(model, sum(λ) == 1)

    @objective(model, Min, 0)

    optimize!(model)

    return termination_status(model) == MOI.OPTIMAL
end
