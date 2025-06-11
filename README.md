# Generation Expansion Planning

This repository is part of the thesis:

**Stochastic Programming for Energy Models: A Blended Cross-Scenario Representative Periods Approach**

The thesis will be made publicly available on [http://repository.tudelft.nl/](http://repository.tudelft.nl/).

## How to Use

1. In the Julia REPL, set the environment variable for your Gurobi installation:

    ```julia
    ENV["GUROBI_HOME"] = "PATH_TO_GUROBI"
    ```

2. Enter package mode by pressing <kbd>]</kbd> and activate the environment in the current directory:

    ```
    pkg> activate .
    pkg> add Gurobi
    pkg> develop ./GenerationExpansionPlanning
    ```

3. Press <kbd>backspace</kbd> to return to the Julia REPL.

You should now be able to run `main.jl` or your own scripts using the `GenerationExpansionPlanning` module.

## Case Studies

Three different case study sets were conducted: `distribution`, `2d`, and `europe`. To access the complete result files and input files, use the following links:

- [Input and output data thesis – part 1 (Zenodo)](https://doi.org/10.5281/zenodo.15584244)
- [Input and output data thesis – part 2 (Zenodo)](https://doi.org/10.5281/zenodo.15584245)
