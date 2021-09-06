include("benchmarks.jl")
RESULTS = run(SUITE; verbose = true)
display(RESULTS)
