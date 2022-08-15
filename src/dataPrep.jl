using CSV, DataFrames

# TODO: Given variables to observe, give back only needed columns
function readAnnotatedData(path, variableNamesRow, variablesToObserve)
    CSV.File(path; header=headerRow) |> DataFrame
end