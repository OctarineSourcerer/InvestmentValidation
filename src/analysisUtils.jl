# Functions to facilitate analysis
using RCall, Statistics, StatsBase

function getCor(x, y; data, method="spearman", exact=false, justVal=false)
    both = data[:, [x,y]] |> dropmissing
    xs, ys = both[:,x], both[:,y]
    if isempty(xs) || isempty(ys)
        return missing
    end
    println("N=$(length(zip(xs)))")
    if justVal
        rcopy(R"cor($(xs), $(ys), method=$(method), exact=$exact)")
    else
        rcopy(R"cor.test($(xs), $(ys), method=$(method), exact=$exact)")
    end
end

function gimmeCorrs(data, relationships)
    df = DataFrame(Aspect_One=Symbol[], Aspect_Two=Symbol[], Correlation=Float64[], PVal=Float64[])
    function addToDF((aspect1, aspect2))
        testResults=getCor(aspect1, aspect2, data=data)
        tuple=(aspect1, aspect2, testResults[:estimate], testResults[:p_value])
        push!(df, tuple)
    end
    addToDF.(relationships)
    @transform!(df, :PVal = :PVal .* nrow(df))
    df
end

function averagesOver(data, target)
    d = groupby(data, target)
    combine(d, aspects .=> mean .=> (x -> "mean_"*x))
end