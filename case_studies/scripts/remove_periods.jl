using DataFrames

function remove_periods_and_update_time_step(file_path::String)
    df = CSV.read(file_path, DataFrame)

    df.time_step .= df.time_step .+ (df.period .- 1) .* 24
    select!(df, Not(:period))
    
    CSV.write(file_path, df)
end

filepaths = [
    "case_studies/optimality/inputs_centered/demand.csv",
    "case_studies/optimality/inputs_centered/generation_availability.csv",
    "case_studies/optimality/inputs_convex/demand.csv",
    "case_studies/optimality/inputs_convex/generation_availability.csv",
    "case_studies/optimality/inputs_softmax/demand.csv",
    "case_studies/optimality/inputs_softmax/generation_availability.csv",
    "case_studies/optimality/inputs_close/demand.csv",
    "case_studies/optimality/inputs_close/generation_availability.csv",
    "case_studies/optimality/inputs_close_mixed/demand.csv",
    "case_studies/optimality/inputs_close_mixed/generation_availability.csv"
]

for filepath in filepaths
    remove_periods_and_update_time_step(filepath)
end
