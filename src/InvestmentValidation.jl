module InvestmentValidation
using DataFramesMeta, Base.Iterators, Chain
include("variables.jl")
include("analysisUtils.jl")
include("dataPrep.jl")
include("paperGraphs.jl")

export shortcut, getData

investmentForms = [:Importance, :Want, :Need, :Investment]
aspects = [investmentForms..., :OwnPower, :EnemyPower, :Tension, :PowerDifference]
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

dataPath="data/annotatedResponsesNumeric.csv"
# Returns (participantData, observations, mashedTogether)
function getData(path=dataPath)
    data = readAnnotatedData(path, 4)
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

function shortcut(dataPath=dataPath)
    (participantData, observations, mashedTogether) = getData(dataPath)

    plotScatters(mashedTogether, meanRelationships)
    plot!(plot_title="By Participant") |> display
    # @df mashedTogether corrplot([:mean_Investment :mean_Tension :mean_OwnPower :mean_EnemyPower], fillcolor=cgrad()) |> display

    byObjective = averagesOver(observations, :objective)
    plotScatters(byObjective, meanRelationships) 
    plot!(plot_title="By Objective") |> display

    println("Correlations within participant")
    gimmeCorrs(mashedTogether, meanRelationships) |> display
    println("Correlations within objective")
    gimmeCorrs(byObjective, meanRelationships) |> display

    println("Different forms of investment")
    investsVsTension = meanTuple.(product(investmentForms, [:Tension]))
    plotScatters(mashedTogether, investsVsTension)
    plot!(plot_title="Different forms of investment") |> display

    gimmeCorrs(mashedTogether, investsVsTension)
end

naughtyList = ["R_3iRuUATOyVe0RUf", "R_25ATgZ4RVxbTMkg"]
# TODO: Check why the heck these participants are outliers. I know I had good reasoning, but... I cannot remember them.
# R_25xxx never made it past killing 3 or 4 enemies, did not interact with anything related to the ritual at all. Also took... half an hour to complete bless their soul
# The otherone seems to be one of two people who never thought the opponents had any power at all really
function markOutliers(participantData, outlierIDs = naughtyList)
    inNaughtyList(id) = id in outlierIDs
    @transform(participantData,
        :outlier = inNaughtyList.(:ParticipantID))
end
# used to remove some of the genuine outlier participants so they can gtfo of my analysis
function outlierExploration(dataPath=dataPath, outlierIDs=naughtyList)
    data = getData(dataPath)
    marked = markOutliers(data.mashedTogether, outlierIDs)

    investsVsTension = meanTuple.(product(investmentForms, [:Tension]))
    plotScatters(marked, investsVsTension, group=marked.outlier, hover=marked.ParticipantID) |> display
    plotScatters(marked, meanRelationships, group=marked.outlier, hover=marked.ParticipantID) |> display
end

# TODO: Graph the different forms of investment.
# TODO: ARE the two outliers? no?

# TODO: WHY are there such weak correlations, particularly in what seems like OwnPower? It seems that OwnPower and EnemyPower CAN be separated, and in this case it's likely to be via confusion. It also means that the correlation between enemy power and own power is weak.
# TODO: Look at particularly strong outliers and see if they're dumpable - is the data cleaner then?

end # module
