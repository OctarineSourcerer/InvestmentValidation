using CSV, DataFrames, DataFramesMeta

function readAnnotatedData(path, variableNamesRow::Int)
    CSV.File(path; header=variableNamesRow) |> DataFrame
end

# TODO: Remove missing parts, give an option to prune rows.

"""
    untangleData(data, primaryKey, singleVars, tangledVar, tangledHeaderFilter, untangleHeader)

Return two dataframes in a tuple: `participantData` contains variables supplied that are just once per participant. `observations` contains every observation measured with tangled questions. Tangled question, you ask? Any question for 

# Arguments
- `data`: The dataframe to untangle.
- `variableNamesRow::Int`: The row in the data that contains annotations saying which variables are measured.
- `primaryKey::String`: Name of variable measured that's unique per response. Usually something like ParticipantID
- `singleVars::Vector{String}`: Variables that are measured once per response, excluding the primary key. For example consent, prior experience etc. This dictates what is returned in `participantData`.
- `tangledHeaderFilter`: A function that returns true for header names that include the tangled variable.
- `untangleHeaderText`: A function that takes a tangled header, and returns the values of BOTH variables measured in that question
"""
function untangleData(data, primaryKey::String, singleVars::Vector{String}, tangledHeaderFilter, untangleHeaderText)
    singleVars = [primaryKey, singleVars...]

    # Each column with an entangled variable, get that variable. Group ones with the same variable. aka partition entangled column names by their entangled variable
    tangledHeaders = filter(tangledHeaderFilter, names(data))

    # Stack: variable column will contain which cluster (element of objectiveColNames) is being measured. And the value for each
    stacked = stack(data, tangledHeaders, [Symbol(primaryKey)])

    @rtransform! stacked $AsTable = untangleHeaderText(:variable)
    observations = stacked[:, Not(:variable)] |> dropmissing
    participantData = DataFrame(data)[:, singleVars]

    (participantData = participantData, observations = observations)
end