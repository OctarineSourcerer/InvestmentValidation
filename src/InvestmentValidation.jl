module InvestmentValidation
using Statistics, RCall, DataFramesMeta
include("variables.jl")
include("dataPrep.jl")
include("paperGraphs.jl")

export shortcut

aspects = [:Importance, :Want, :Need, :Investment, :OwnPower, :EnemyPower, :Tension, :PowerDifference]
relationships = [
    (:Investment, :Tension),
    (:EnemyPower, :OwnPower),
    (:OwnPower, :Tension),
    (:EnemyPower, :Tension),
    (:PowerDifference, :Tension)
]
meanTuple(t) = ["mean_$x" |> Symbol for x in t] |> Tuple
meanRelationships = map(meanTuple, relationships)

function objectiveAspectPair(dataHeader::String)
    result = match(r"Objective\((?'objective'\w+)\), (?'aspect'\w+)", dataHeader)
    (objective = result[:objective], aspect = result[:aspect])
end
objectiveHeaders(x) = contains(x, "Objective")
singleVars = ["Consent", "Experience", "RitualCritical", "AttackMages", "AttackYaltha"]

function averagesOver(data, target)
    d = groupby(data, target)
    combine(d, aspects .=> mean .=> (x -> "mean_"*x))
end

# Returns (participantData, observations, mashedTogether)
function getData()
    data = readAnnotatedData("data/annotatedResponsesNumeric.csv", 4)
    initialLength = nrow(data)
    println("$initialLength rows")
    data = @subset(data, 
        :Progress .>= 50,
        :Status .!== 1,
        :Consent .=== 1,
        :DurationSeconds .> 30,
    )
    println("Dropped $(initialLength - nrow(data)) rows of invalid data")
    println("$(nrow(data)) rows of valid data")

    (participantData, observations) = untangleData(data, :ParticipantID, singleVars, objectiveHeaders, objectiveAspectPair)
    observations = unstack(observations, :aspect, :value) |> dropmissing
    @transform!(observations, :PowerDifference = :OwnPower .- :EnemyPower)

    (participantData = participantData, 
        observations = observations,
        mashedTogether = innerjoin(averagesOver(observations, :ParticipantID), participantData, on=:ParticipantID))
end

function getCor(x, y; data, method="spearman", justVal=false)
    both = data[:, [x,y]] |> dropmissing
    xs, ys = both[:,x], both[:,y]
    if isempty(xs) || isempty(ys)
        return missing
    end
    println("N=$(length(zip(xs)))")
    if justVal
        rcopy(R"cor($(xs), $(ys), method=$(method))")
    else
        rcopy(R"cor.test($(xs), $(ys), method=$(method))")
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

function shortcut()
    (participantData, observations, mashedTogether) = getData()
    plotScatters(mashedTogether, meanRelationships)
    plot!(plot_title="By Participant") |> display
    # @df participantAverages corrplot([:Investment :Tension :OwnPower :EnemyPower], fillcolor=cgrad()) |> display

    byObjective = averagesOver(observations, :objective)
    plotScatters(byObjective, meanRelationships) 
    plot!(plot_title="By Objective") |> display

    println("Correlations within participant")
    gimmeCorrs(mashedTogether, meanRelationships) |> display
    
    println("Correlations within objective")
    gimmeCorrs(byObjective, meanRelationships) |> display
end

# TODO: Graph the different forms of investment.
# TODO: WHY are there such weak correlations, particularly in what seems like OwnPower? It seems that OwnPower and EnemyPower CAN be separated, and in this case it's likely to be via confusion. It also means that the correlation between enemy power and own power is weak.

end # module
