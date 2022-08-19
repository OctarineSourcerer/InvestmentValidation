using CSV, DataFrames, DataFramesMeta

# TODO: Make this general
# We want to observe ID -> per-participant things
# And separately, ID, objective, aspect...
# Why? because those objectives and aspects are multiple times per participant, the others just once per participants
# I'm gonna call these Tangled questions
function readAnnotatedData(path, variableNamesRow, variablesToObserve)
    primaryKey = "ParticipantID"
    singleVars = [primaryKey, "Consent", "Experience", "RitualCritical", "AttackMages", "AttackYaltha"]
    implicitVar = :objective # The *hidden* variable - the one we need to shrink columns and expand rows for

    function objectiveAspectPair(colName::String)
        result = match(r"Objective\((?'objective'\w+)\), (?'aspect'\w+)", colName)
        (objective = result[:objective], aspect = result[:aspect])
    end
    # Each column with an entangled variable, get that variable. Group ones with the same variable. aka partition entangled column names by their entangled variable
    df = CSV.File(path; header=variableNamesRow) |> DataFrame
    objectiveColNames = filter(x -> contains(x, "Objective"), names(df))

    # Stack: variable column will contain which cluster (element of objectiveColNames) is being measured. And the value for each
    stacked = stack(df, objectiveColNames, [:ParticipantID])
    @transform! stacked @astable begin 
    parts = map(objectiveAspectPair, :variable) # Can't broadcast here for some reason. I think dataframesMeta is dying on the sumbol replacement?!
        :Objective = map(x -> getproperty(x, ^(:objective)), parts)
        :Aspect = map(x -> getproperty(x, ^(:aspect)), parts)
    end
    observations = stacked[:, Not(:variable)] |> dropmissing
    participantData = DataFrame(df)[:, singleVars]
    (observations, participantData)
end