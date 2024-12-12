export ExperimentData, ExperimentResult, SecondStageData

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
    periods_per_scenario::Vector{Tuple{Int,Symbol}}

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
    time_frame::Int

    function ExperimentData(config_dict::Dict{Symbol,Any})
        sets = config_dict[:sets]
        data = config_dict[:data]
        scalars = data[:scalars]
        rp = config_dict[:rp]

        return new(
            sets[:time_steps],
            sets[:locations],
            sets[:scenarios],
            sets[:transmission_lines],
            sets[:generators],
            sets[:generation_technologies],
            rp[:periods],
            rp[:periods_per_scenario],
            data[:demand],
            data[:generation_availability],
            data[:generation],
            data[:transmission_lines],
            data[:scenario_probabilities],
            rp[:period_weights],
            scalars[:value_of_lost_load],
            scalars[:relaxation],
            rp[:time_frame]
        )
    end
end

struct SecondStageData
    # Sets
    time_steps::Vector{Int}
    locations::Vector{Symbol}
    scenarios::Vector{Symbol}
    transmission_lines::Vector{Tuple{Symbol,Symbol}}
    generators::Vector{Tuple{Symbol,Symbol}}
    generation_technologies::Vector{Symbol}
    periods::Vector{Int}
    periods_per_scenario::Vector{Tuple{Int,Symbol}}

    # Dataframes
    demand::AbstractDataFrame
    generation_availability::AbstractDataFrame
    generation::AbstractDataFrame
    transmission_capacities::AbstractDataFrame
    scenario_probabilities::AbstractDataFrame
    period_weights::Vector{Float64}
    investment::AbstractDataFrame

    # Scalars
    value_of_lost_load::Float64
    relaxation::Bool
    total_investment_cost::Float64
    time_frame::Int

    function SecondStageData(config_dict::Dict{Symbol,Any})
        sets = config_dict[:sets]
        data = config_dict[:data]
        scalars = data[:scalars]
        rp = config_dict[:rp]
        secondStage = config_dict[:secondStage]

        return new(
            secondStage[:time_steps],
            sets[:locations],
            sets[:scenarios],
            sets[:transmission_lines],
            secondStage[:generators],
            secondStage[:generation_technologies],
            secondStage[:periods],
            secondStage[:periods_per_scenario],
            secondStage[:demand],
            secondStage[:generation_availability],
            data[:generation],
            data[:transmission_lines],
            data[:scenario_probabilities],
            secondStage[:period_weights],
            secondStage[:investment],
            scalars[:value_of_lost_load],
            scalars[:relaxation],
            secondStage[:total_investment_cost],
            secondStage[:time_frame]
        )
    end
end

struct ExperimentResult
    total_cost::Float64
    total_investment_cost::Float64
    total_operational_cost::Float64
    investment::AbstractDataFrame
    production::AbstractDataFrame
    line_flow::AbstractDataFrame
    loss_of_load::AbstractDataFrame
    runtime::Float64

    function ExperimentResult(
        total_cost::Float64,
        total_investment_cost::Float64,
        total_operational_cost::Float64,
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
            investment,
            production,
            line_flow,
            loss_of_load,
            runtime
        )
    end
end
