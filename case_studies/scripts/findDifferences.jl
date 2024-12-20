using JSON
using DataFrames
using CSV


function compare_json_files(file1::String, file2::String)
    data1 = JSON.parsefile(file1)
    data2 = JSON.parsefile(file2)
    
    differences = Dict()
    
    for key in union(keys(data1), keys(data2))
        if haskey(data1, key) && haskey(data2, key)
            if data1[key] != data2[key]
                differences[key] = (data1[key], data2[key])
            end
        else
            differences[key] = (haskey(data1, key) ? data1[key] : "missing", haskey(data2, key) ? data2[key] : "missing")
        end
    end

    
    return differences
end

file1 = "./case_studies/stylized_EU/configs_test/newtest1.json"
file2 = "./case_studies/stylized_EU/configs_test/newtest2.json"
differences = compare_json_files(file1, file2)
diff_count = 0

for key in keys(differences)
    println("Key: $key")
    val1, val2 = differences[key]
    if isa(val1, Dict) && isa(val2, Dict)
        for subkey in union(keys(val1), keys(val2))
            if haskey(val1, subkey) && haskey(val2, subkey)
                if val1[subkey] != val2[subkey]
                    println("  Subkey: $subkey")
                    global diff_count += 1
                    println("  File1: ", val1[subkey])
                    println("  File2: ", val2[subkey])
                    println()
                end
            else
                println("  Subkey: $subkey")
                println("  File1: ", haskey(val1, subkey) ? val1[subkey] : "missing")
                println("  File2: ", haskey(val2, subkey) ? val2[subkey] : "missing")
                println()
            end
        end
    else
        println("File1: ", val1)
        println("File2: ", val2)
        println()
    end
end

println("diff_count     = $diff_count")
function compare_csv_files(file1::String, file2::String)
    df1 = CSV.read(file1, DataFrame)
    df2 = CSV.read(file2, DataFrame)
    
    differences = DataFrame(location=String[], technology=String[], rep_period=Int[], time_step=Int[], scenario=Int[], file1=Float64[], file2=Float64[])
    
    for row1 in eachrow(df1)
        row2 = filter(r -> r.location == row1.location && r.technology == row1.technology && r.rep_period == row1.rep_period && r.time_step == row1.time_step && r.scenario == row1.scenario, eachrow(df2))
        if !isempty(row2)
            row2 = row2[1]
            if row1.production != row2.production
                push!(differences, (location=row1.location, technology=row1.technology, rep_period=row1.rep_period, time_step=row1.time_step, scenario=row1.scenario, file1=row1.production, file2=row2.production))
            end
        end
    end
    
    return differences
end

# csv_file1 = "./case_studies/stylized_EU/configs_test/output/test1/production.csv"
# csv_file2 = "./case_studies/stylized_EU/configs_test/output/test2/production.csv"
# csv_differences = compare_csv_files(csv_file1, csv_file2)

# println("CSV Differences:")
# println(csv_differences)