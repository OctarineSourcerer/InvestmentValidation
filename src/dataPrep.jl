using CSV, DataFrames

function readData(path)
    CSV.File(path) |> DataFrame
end