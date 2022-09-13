module InvestmentValidation
using Statistics
include("variables.jl")
include("dataPrep.jl")
include("paperGraphs.jl")

export shortcut

function objectiveAspectPair(dataHeader::String)
    result = match(r"Objective\((?'objective'\w+)\), (?'aspect'\w+)", dataHeader)
    (objective = result[:objective], aspect = result[:aspect])
end
objectiveHeaders(x) = contains(x, "Objective")
singleVars = ["Consent", "Experience", "RitualCritical", "AttackMages", "AttackYaltha"]

# Returns (participantData, observations)
function getData()
    data = readAnnotatedData("data/annotatedResponsesNumeric.csv", 4)
    untangleData(data, :ParticipantID, singleVars, objectiveHeaders, objectiveAspectPair)
end

function shortcut()
    aspects = [:Importance, :Want, :Need, :Investment, :OwnPower, :EnemyPower, :Tension]

    (participantData, observations) = getData()
    unstacked = unstack(observations, :aspect, :value) |> dropmissing
    byPart = groupby(unstacked, :ParticipantID)
    participantAverages = combine(byPart, aspects .=> mean .=> aspects)
    plotScatters(participantAverages)
end

end # module
