using VarInfoX
using Test

# Ignore some objects (just enough for pass these particular test; maybe more
# things should be ignored).
ignore_some_rows(rows) = filter(((name,),) -> name ∉ ("Workqueue", "uvhandles"), rows)

@testset "VarInfoX.jl" begin
    a = VarInfoX.varinfo_seq(Base; recursive = true, all = true)
    b = VarInfoX.varinfo_dac_module(Base; recursive = true, all = true)
    c = VarInfoX.varinfo_parallel_names(Base; recursive = true, all = true)
    a = ignore_some_rows(a)
    b = ignore_some_rows(b)
    c = ignore_some_rows(c)
    @test Set(a) == Set(b) == Set(c)
end
