module VarInfoX

Base.Experimental.@optlevel 1  # as done in InteractiveUtils.jl

using Base: format_bytes, summarysize
using FLoops: @floop, @reduce, ThreadedEx

function varinfo_seq(
    m::Module = Main,
    pattern::Regex = r"";
    all::Bool = false,
    imported::Bool = false,
    recursive::Bool = false,
)
    rows = Vector{Any}[]
    workqueue = [(m, "")]
    while !isempty(workqueue)
        m2, prep = popfirst!(workqueue)
        for v in names(m2; all, imported)
            if !isdefined(m2, v) || !occursin(pattern, string(v))
                continue
            end
            value = getfield(m2, v)
            isbuiltin = value === Base || value === Main || value === Core
            if (
                recursive &&
                !isbuiltin &&
                isa(value, Module) &&
                value !== m2 &&
                nameof(value) === v &&
                parentmodule(value) === m2
            )
                push!(workqueue, (value, "$prep$v."))
            end
            ssize_str, ssize = if isbuiltin
                ("", typemax(Int))
            else
                ss = summarysize(value)
                (format_bytes(ss), ss)
            end
            push!(rows, Any[string(prep, v), ssize_str, summary(value), ssize])
        end
    end
    return rows
end

function varinfo_dac_module(
    m::Module = Main,
    pattern::Regex = r"";
    all::Bool = false,
    imported::Bool = false,
    recursive::Bool = false,
)
    return _varinfo_dac_module(m, ""; all, imported, pattern, recursive)
end

# https://github.com/JuliaLang/julia/pull/42123#issuecomment-913216582
function _varinfo_dac_module(m2, prep; all, imported, pattern, recursive)
    local_rows = Vector{Any}[]
    local_tasks = []
    @sync for v in names(m2; all, imported)
        if !isdefined(m2, v) || !occursin(pattern, string(v))
            continue
        end
        value = getfield(m2, v)
        isbuiltin = value === Base || value === Main || value === Core
        if (
            recursive &&
            !isbuiltin &&
            isa(value, Module) &&
            value !== m2 &&
            nameof(value) === v &&
            parentmodule(value) === m2
        )
            task = Threads.@spawn _varinfo_dac_module(
                value,
                "$prep$v.";
                all,
                imported,
                pattern,
                recursive,
            )
            push!(local_tasks, task)
        end
        ssize_str, ssize = if isbuiltin
            ("", typemax(Int))
        else
            ss = summarysize(value)
            (format_bytes(ss), ss)
        end
        push!(local_rows, Any[string(prep, v), ssize_str, summary(value), ssize])
    end
    foreach(local_tasks) do task
        append!(local_rows, fetch(task))
    end
    return local_rows
end

function varinfo_parallel_names(
    m::Module = Main,
    pattern::Regex = r"";
    all::Bool = false,
    imported::Bool = false,
    recursive::Bool = false,
    executor = ThreadedEx(basesize = 32),  # hand-tuned for `m == Base` case
)
    return _varinfo_parallel_names(m, ""; all, imported, pattern, recursive, executor)
end

function _varinfo_parallel_names(m2, prep; all, imported, pattern, recursive, executor)
    @floop executor for v in names(m2; all, imported)
        if !isdefined(m2, v) || !occursin(pattern, string(v))
            continue
        end
        local_rows = Vector{Any}[]
        value = getfield(m2, v)
        isbuiltin = value === Base || value === Main || value === Core
        if (
            recursive &&
            !isbuiltin &&
            isa(value, Module) &&
            value !== m2 &&
            nameof(value) === v &&
            parentmodule(value) === m2
        )
            append!(
                local_rows,
                _varinfo_parallel_names(
                    value,
                    "$prep$v.";
                    all,
                    imported,
                    pattern,
                    recursive,
                    executor,
                ),
            )
        end
        ssize_str, ssize = if isbuiltin
            ("", typemax(Int))
        else
            ss = summarysize(value)
            (format_bytes(ss), ss)
        end
        push!(local_rows, Any[string(prep, v), ssize_str, summary(value), ssize])
        @reduce(rows = append!(Vector{Any}[], local_rows))
    end
    return rows
end

end  # module VarInfoX
