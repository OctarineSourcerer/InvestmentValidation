using DataFrames, DataFramesMeta, OrderedCollections

struct Variable
    name::String
    independent::Bool
end

"Ask the user for a set of variables to tag onto questions, for easy checking"
function askForVariables()
    variables = []
    println("Which variables exist in this study? For example, (without quotes) 'Objective' or 'Tension'. Note that this will not return duplicate copies.")
    println("Write an empty line to end here.")
    while true
        print("Variable: ")
        observation = readline()
        if observation == "" break end
        push!(variables, observation)
    end

    vars = Variable[]
    println()
    println("Which of these are independent variables? (eg '1 3')")
    while true
        for (i, var) in enumerate(variables)
            printstyled("$i: ", color=:blue)
            println(var)
        end
        input =  readline()
        if input == ""
            return missing
        end
        elements = split(input, " ")
        try
            numbers = map( x -> parse(Int, x), elements)
            if !all(i -> i > 0 && i <= lastindex(variables), numbers)
                error("User supplied number outside bounds of variables given")
            end
        catch
            println("Please only write numbers")
            continue
        end
    end
end

function askForVariableValues(variableSet::Set, enforceAllSet=true)
    results = Dict()
    for variableName in variableSet
        print("$(variableName): ")
        value = readline()
        if value == "" 
            if enforceAllSet 
                return missing
            end
            results[variableName] = missing
        else
            results[variableName] = value
        end
    end
    results
end

function tagData(data, variableSet::Set)
    colNames = names(data)
    for colName in colNames
        column = data[:, colName]
        println("Column $(colName)")
        vars = askForVariableValues(variableSet)

    end
end