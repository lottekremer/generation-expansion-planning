export run_experiment

function run_experiment(data::ExperimentData, optimizer_factory)::ExperimentResult
    # 1. Extract data into local variables
    @info "Reading the sets"
    N = data.locations
    G = data.generation_technologies
    NG = data.generators
    T = data.time_steps
    L = data.transmission_lines
    S = data.scenarios

    @info "Converting dataframes to dictionaries"
    filter!(row -> row.time_step ∈ T, data.demand)
    filter!(row -> row.scenario ∈ S, data.demand)
    filter!(row -> row.time_step ∈ T, data.generation_availability)
    filter!(row -> row.scenario ∈ S, data.generation_availability)
    demand = dataframe_to_dict(data.demand, [:location, :time_step, :scenario], :demand)
    generation_availability = dataframe_to_dict(data.generation_availability, [:location, :technology, :time_step, :scenario], :availability)
    investment_cost = dataframe_to_dict(data.generation, [:location, :technology], :investment_cost)

    variable_cost = dataframe_to_dict(data.generation, [:location, :technology], :variable_cost)
    unit_capacity = dataframe_to_dict(data.generation, [:location, :technology], :unit_capacity)
    ramping_rate = dataframe_to_dict(data.generation, [:location, :technology], :ramping_rate)
    export_capacity = dataframe_to_dict(data.transmission_capacities, [:from, :to], :export_capacity)
    import_capacity = dataframe_to_dict(data.transmission_capacities, [:from, :to], :import_capacity)

    @info "Solving the problem"
    dt = @elapsed begin
        # 2. Add variables to the model
        @info "Populating the model"
        model = JuMP.Model(optimizer_factory)
        @info "Adding the variables"
        @variable(model, 0 ≤ total_investment_cost)
        @variable(model, 0 ≤ total_operational_cost)
        @variable(model, 0 ≤ investment[n ∈ N, g ∈ G; (n, g) ∈ NG], integer = !data.relaxation)
        @variable(model, 0 ≤ production[n ∈ N, g ∈ G, t ∈ T, s ∈ S; (n, g) ∈ NG])
        @variable(model,
            -import_capacity[n_from, n_to] ≤
            line_flow[n_from ∈ N, n_to ∈ N, t ∈ T, s ∈ S; (n_from, n_to) ∈ L] ≤
            export_capacity[n_from, n_to]
        )
        @variable(model, 0 ≤ loss_of_load[n ∈ N, t ∈ T, s ∈ S] ≤ demand[n, t, s])

        @info "Precomputing expressions"
        investment_MW = @expression(model, [n ∈ N, g ∈ G; (n, g) ∈ NG], unit_capacity[n, g] * investment[n, g])

        # 3. Add an objective to the model
        @info "Adding the objective"
        @objective(model, Min, total_investment_cost + total_operational_cost)

        # 4. Add constraints to the model
        @info "Adding the constraints"
        @info "Adding the cost constraints"
        @constraint(model, total_investment_cost == sum(investment_cost[n, g] * investment_MW[n, g] for (n, g) ∈ NG))
        # TODO: add variable probability for scenarios
        @constraint(model,
            total_operational_cost
            ==
            (1 / length(S))  * (8760 / length(T))
            (sum(variable_cost[n, g] * production[n, g, t, s] for (n, g) ∈ NG, t ∈ T, s ∈ S)
             +
             data.value_of_lost_load * sum(loss_of_load[n, t, s] for n ∈ N, t ∈ T, s ∈ S))
        )

        # Node balance
        @info "Adding the balance constraints"
        @constraint(model, [n ∈ N, t ∈ T, s ∈ S],
            sum(production[n, g, t, s] for g ∈ G if (n, g) ∈ NG)
            +
            sum(line_flow[n_from, n_to, t, s] for (n_from, n_to) ∈ L if n_to == n)
            -
            sum(line_flow[n_from, n_to, t, s] for (n_from, n_to) ∈ L if n_from == n)
            +
            loss_of_load[n, t, s]
            ==
            demand[n, t, s]
        )

        # Maximum production
        @info "Adding the maximum production constraints"
        # for technologies without the availability profile, the availability is 
        # always equal to 100%, that is, 1.0. This is why we use
        # get(generation_availability, (n, g, t), 1.0) and not
        # generation_availability[n, g, t]
        @constraint(model, [n ∈ N, g ∈ G, t ∈ T, s ∈ S; (n, g) ∈ NG],
            production[n, g, t, s] ≤ get(generation_availability, (n, g, t, s), 1.0) * investment_MW[n, g]
        )

        @info "Adding the ramping constraints"
        ramping = @expression(model, [n ∈ N, g ∈ G, t ∈ T, s ∈ S; t > 1 && (n, g) ∈ NG],
            production[n, g, t, s] - production[n, g, t-1, s]
        )
        for (n, g, t, s) ∈ eachindex(ramping)
            # Ramping up
            @constraint(model, ramping[n, g, t, s] ≤ ramping_rate[n, g] * investment_MW[n, g])
            # Ramping down
            @constraint(model, ramping[n, g, t, s] ≥ -ramping_rate[n, g] * investment_MW[n, g])
        end

        # 5. Solve the model
        @info "Solving the model"
        optimize!(model)
    end

    investment_type = if data.relaxation
        Float64
    else
        Int
    end

    investment_decisions_units = jump_variable_to_df(investment; dim_names=(:location, :technology), value_name=:units, value_type=investment_type)
    investment_decisions_MW = jump_variable_to_df(investment_MW; dim_names=(:location, :technology), value_name=:capacity)
    investment_decisions = leftjoin(investment_decisions_MW, investment_decisions_units, on=[:location, :technology])

    production_decisions = jump_variable_to_df(production; dim_names=(:location, :technology, :time_step, :scenario), value_name=:production)
    line_flow_decisions = jump_variable_to_df(line_flow; dim_names=(:from, :to, :time_step, :scenario), value_name=:flow)
    loss_of_load_decisions = jump_variable_to_df(loss_of_load; dim_names=(:location, :time_step, :scenario), value_name=:loss_of_load)

    return ExperimentResult(
        value.(total_investment_cost),
        value.(total_operational_cost),
        investment_decisions,
        production_decisions,
        line_flow_decisions,
        loss_of_load_decisions,
        dt
    )
end
