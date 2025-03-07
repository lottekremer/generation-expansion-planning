export ExperimentData, ExperimentResult, FixedData, RepData

"""
Data needed to run a single experiment (i.e., a single optimization model)
"""
struct ExperimentData
    # Sets
    time_steps::Vector{Int}
    locations::Vector{Symbol}
    scenarios::Vector{Symbol}
    transmission_lines::Vector{Tuple{Symbol,Symbol}}
    generators::Vector{Tuple{Symbol,Symbol}}
    generation_technologies::Vector{Symbol}
    periods::Vector{Int}

    # Dataframes
    demand::AbstractDataFrame
    generation_availability::AbstractDataFrame
    generation::AbstractDataFrame
    transmission_capacities::AbstractDataFrame
    scenario_probabilities::AbstractDataFrame

    # Scalars
    value_of_lost_load::Float64
    relaxation::Bool
    inter_period::Bool

    function ExperimentData(config_dict::Dict{Symbol,Any})
        sets = config_dict[:sets]
        data = config_dict[:data]
        scalars = data[:scalars]

        return new(
            sets[:time_steps],
            sets[:locations],
            sets[:scenarios],
            sets[:transmission_lines],
            sets[:generators],
            sets[:generation_technologies],
            sets[:periods],
            data[:demand],
            data[:generation_availability],
            data[:generation],
            data[:transmission_lines],
            data[:scenario_probabilities],
            scalars[:value_of_lost_load],
            scalars[:relaxation],
            scalars[:inter_period]
        )
    end
end

struct RepData
    # Sets
    time_steps::Vector{Int}
    locations::Vector{Symbol}
    scenarios::Vector{Symbol}
    transmission_lines::Vector{Tuple{Symbol,Symbol}}
    generators::Vector{Tuple{Symbol,Symbol}}
    generation_technologies::Vector{Symbol}
    rep_periods::Vector{Int}
    rep_periods_per_scenario::Vector{Tuple{Int,Symbol}}

    # Dataframes
    demand::AbstractDataFrame
    generation_availability::AbstractDataFrame
    generation::AbstractDataFrame
    transmission_capacities::AbstractDataFrame
    scenario_probabilities::AbstractDataFrame
    period_weights::Vector{Float64}

    # Scalars
    value_of_lost_load::Float64
    relaxation::Bool
    annualization::Float64

    function RepData(config_dict::Dict{Symbol,Any})
        sets = config_dict[:sets]
        data = config_dict[:data]
        scalars = data[:scalars]
        rp = config_dict[:rp]

        return new(
            sets[:time_steps],
            sets[:locations],
            rp[:scenarios],
            sets[:transmission_lines],
            sets[:generators],
            sets[:generation_technologies],
            rp[:rep_periods],
            rp[:rep_periods_per_scenario],
            rp[:demand],
            rp[:generation_availability],
            data[:generation],
            data[:transmission_lines],
            rp[:scenario_probabilities],
            rp[:weights],
            scalars[:value_of_lost_load],
            scalars[:relaxation],
            rp[:annualization]
            )
    end
end

struct FixedData
    # Sets
    time_steps::Vector{Int}
    locations::Vector{Symbol}
    scenarios::Vector{Symbol}
    transmission_lines::Vector{Tuple{Symbol,Symbol}}
    generators::Vector{Tuple{Symbol,Symbol}}
    generation_technologies::Vector{Symbol}
    periods::Vector{Int}
    
    # Dataframes
    demand::AbstractDataFrame
    generation_availability::AbstractDataFrame
    generation::AbstractDataFrame
    transmission_capacities::AbstractDataFrame
    scenario_probabilities::AbstractDataFrame
    investment::AbstractDataFrame

    # Scalars
    value_of_lost_load::Float64
    relaxation::Bool
    total_investment_cost::Float64
    inter_period::Bool

    function FixedData(config_dict::Dict{Symbol,Any})
        sets = config_dict[:sets]
        data = config_dict[:data]
        scalars = data[:scalars]
        fixed = config_dict[:fixed]

        return new(
            sets[:time_steps],
            sets[:locations],
            sets[:scenarios],
            sets[:transmission_lines],
            fixed[:generators],
            fixed[:generation_technologies],
            sets[:periods],
            data[:demand],
            data[:generation_availability],
            data[:generation],
            data[:transmission_lines],
            data[:scenario_probabilities],
            fixed[:investment],
            scalars[:value_of_lost_load],
            scalars[:relaxation],
            fixed[:total_investment_cost],
            scalars[:inter_period]        
            )
    end
end

struct ExperimentResult
    total_cost::Float64
    total_investment_cost::Float64
    total_operational_cost::Float64
    operational_cost_per_scenario::AbstractDataFrame
    investment::AbstractDataFrame
    production::AbstractDataFrame
    line_flow::AbstractDataFrame
    loss_of_load::AbstractDataFrame
    runtime::Float64
    
    function ExperimentResult(
        total_cost::Float64,
        total_investment_cost::Float64,
        total_operational_cost::Float64,
        operational_cost_per_scenario::DataFrame,
        investment::DataFrame,
        production::DataFrame,
        line_flow::DataFrame,
        loss_of_load::DataFrame,
        runtime::Float64
        )
        return new(
            total_cost,
            total_investment_cost,
            total_operational_cost,
            operational_cost_per_scenario,
            investment,
            production,
            line_flow,
            loss_of_load,
            runtime
        )
    end
end