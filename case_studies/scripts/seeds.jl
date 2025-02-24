using Random
using JSON

for i in 6:10
    seeds = Dict()
    for key in 3:2:41
        seeds[string(key)] = rand(UInt32)
    end
    open("seeds$(i).json", "w") do io
        JSON.print(io, seeds)
    end
end