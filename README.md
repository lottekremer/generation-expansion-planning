# How to Use

In julia REPL, add the environment variable for your Gurobi installation

```julia
ENV["GUROBI_HOME"] = "PATH_TO_GUROBI"
```

Then go to the package mode by pressing <kbd>]</kbd>, and activate the environment in the current directory:
```
pkg> activate .
pkg> add Gurobi
pkg> develop ./GenerationExpansionPlanning
```

Press <kbd>backspace</kbd> to return to Julia REPL.

You should be able to run `main.jl` or your own scripts using `GenerationExpansionPlanning` module now.

# Thesis

This repository is part of the following thesis: 

# Case studies

Three different case studie sets were conducted: distribution, 2d, europe. To access the complete result files, use the following link:

To access the input data for the european case study or distrubution case studies, use the following link:
