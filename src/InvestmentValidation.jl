module InvestmentValidation
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
    (participantData, observations) = getData()
    unstacked = unstack(observations, :aspect, :value) |> dropmissing
    
end

end # module
