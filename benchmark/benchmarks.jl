using VarInfoX
using BenchmarkTools

SUITE = BenchmarkGroup()

SUITE["seq"] = @benchmarkable VarInfoX.varinfo_seq(Base; recursive = true, all = true)
# SUITE["pr42123"] =
#     @benchmarkable VarInfoX.varinfo_pr42123(Base; recursive = true, all = true)
SUITE["dac_names"] =
    @benchmarkable VarInfoX.varinfo_dac_names(Base; recursive = true, all = true)
SUITE["dac_module"] =
    @benchmarkable VarInfoX.varinfo_dac_module(Base; recursive = true, all = true)
SUITE["parallel_names"] =
    @benchmarkable VarInfoX.varinfo_parallel_names(Base; recursive = true, all = true)
