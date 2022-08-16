using CSV, DataFrames

# TODO: Given variables to observe, give back only needed columns
# We want to observe ID -> per-participant things
# And separately, ID, objective, aspect...
# Why? because those objectives and aspects are multiple times per participant, the others just once per participants
function readAnnotatedData(path, variableNamesRow, variablesToObserve)
    CSV.File(path; header=variableNamesRow) |> DataFrame
end