using JSON
using DataFrames

function compare_json_files(file1::String, file2::String)
    data1 = JSON.parsefile(file1)
    data2 = JSON.parsefile(file2)
    
    differences = Dict()
    
    for key in union(keys(data1), keys(data2))
        if haskey(data1, key) && haskey(data2, key)
            if data1[key] != data2[key]
                differences[key] = (data1[key], data2[key])
                println("test")
            end
        else
            differences[key] = (haskey(data1, key) ? data1[key] : "missing", haskey(data2, key) ? data2[key] : "missing")
        end
    end
    
    return differences
end

file1 = "./case_studies/stylized_EU/configs_test/output/test1_input_data.json"
file2 = "./case_studies/stylized_EU/configs_test/output/test2_input_data.json"
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