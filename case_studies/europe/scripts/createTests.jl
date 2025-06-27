using TOML

dir = readdir("./case_studies/europe/configs")

initial_run_dirs = String[]
for d in dir
    if endswith(d, ".toml")
        continue
    end
    subdirs = readdir(joinpath("./case_studies/europe/configs", d))
    for sub in subdirs
        if sub == "initial_run"
            push!(initial_run_dirs, joinpath("./case_studies/europe/configs", d, sub))
        else
            subsubdirs = readdir(joinpath("./case_studies/europe/configs", d, sub))
            for subsub in subsubdirs
                if subsub == "initial_run"
                    push!(initial_run_dirs, joinpath("./case_studies/europe/configs", d, sub, subsub))
                end
            end
        end
    end
end
scenarios = ["1982", "1986", "1990", "1994", "1998", "2004", "2008", "2011", "2012", "2016"]
config_path = joinpath("./case_studies/europe/configs", "start.toml")
config = TOML.parsefile(config_path)

config["input"]["rp"]["use_periods"] = false
config["input"]["fixed"] = Dict()
config["input"]["fixed"]["fixed_run"] = true

global i = 1

for s in scenarios
    for fixed_dir in initial_run_dirs
        config["input"]["sets"]["scenarios"] = [s]
        config["input"]["fixed"]["dir"] = fixed_dir
        config["input"]["fixed"]["investment"] = "investment.csv"
        config["input"]["fixed"]["total_investment_cost"] = "scalars.toml"

        new_toml_path = joinpath("./case_studies/europe/configs", "start_$i.toml")
        open(new_toml_path, "w") do file
            TOML.print(file, config)
        end
        global i += 1

    end
end
