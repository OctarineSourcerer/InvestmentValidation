module InvestmentValidation
include("variables.jl")
include("dataPrep.jl")

export shortcut

function objectiveAspectPair(dataHeader::String)
    result = match(r"Objective\((?'objective'\w+)\), (?'aspect'\w+)", dataHeader)
    (objective = result[:objective], aspect = result[:aspect])
end
objectiveHeaders(x) = contains(x, "Objective")
singleVars = ["Consent", "Experience", "RitualCritical", "AttackMages", "AttackYaltha"]

function shortcut()
    data = readAnnotatedData("data/annotatedResponses.csv", 4)
    untangleData(data, :ParticipantID, singleVars, objectiveHeaders, objectiveAspectPair)
end

end # module
