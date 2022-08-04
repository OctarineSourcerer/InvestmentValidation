using DataFrames, DataFramesMeta, OrderedCollections

# Mutable for now so it's easy to construct a list of em
mutable struct Variable
    name::String
    independent::Bool
end
# Values used to colour dependent and independent variables
const independentColour = :yellow
const dependentColour = :light_blue
function getVarColor(var)
    if var.independent independentColour else dependentColour end
end

"Ask the user for a set of variables to tag onto questions, for easy checking"
function askForVariables()
    variables = Vector{Variable}()
    println("Which variables exist in this study? For example, (without quotes) 'Objective' or 'Tension'. Note that this will not return duplicate copies.")
    println("Write an empty line to end here.")
    while true
        print("Variable: ")
        input = readline()
        if input == "" break end
        push!(variables, Variable(input, false))
    end

    println()
    while true
        print("Choose which variables to toggle between "); printstyled("dependent", color=dependentColour); print(" and "); printstyled("independent", color=independentColour); println(" (eg '1 3')")
        for (i, var) in enumerate(variables)
            printstyled("$i: ", color=getVarColor(var))
            println(var.name)
        end
        input =  readline()
        if input == ""
            break
        end
        elements = split(input, " ")
        try
            numbers = map(x -> parse(Int, x), elements)
            if !all(i -> i > 0 && i <= lastindex(variables), numbers)
                error("User supplied number outside bounds of variables given")
            end
            for num in numbers
                v = variables[num]
                v.independent = !v.independent
            end
        catch
            println("Please only write numbers")
            continue
        end
    end
    variables
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