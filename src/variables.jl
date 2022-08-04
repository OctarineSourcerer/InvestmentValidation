using DataFrames, DataFramesMeta, OrderedCollections, JSON
export Variable

struct Variable
    name::String
    independent::Bool
end
# Values used to colour dependent and independent variables
const independentColour = :yellow
const dependentColour = :light_blue
function getVarColor(var)
    if var.independent independentColour else dependentColour end
end

"Ask the user for a set of variables that are present"
function askForVariables(inputStream=stdin)::Vector{Variable}
    variables = []
    println("Which variables exist in this study? For example, (without quotes) 'Objective' or 'Tension'. Note that this will not return duplicate copies.")
    println("Write an empty line to end here.")
    # Get a list of variable names. set them all to dependent by default
    while true
        print("Variable: ")
        input = readline(inputStream)
        if input == "" break end
        push!(variables, Variable(input, false))
    end

    println()
    # Allow the user to toggle dependence of any of the variables they've specified so far
    while true
        print("Choose which variables to toggle between "); printstyled("dependent", color=dependentColour); print(" and "); printstyled("independent", color=independentColour); println(" (eg '1 3')")
        for (i, var) in enumerate(variables)
            printstyled("$i: ", color=getVarColor(var))
            println(var.name)
        end
        input = readline(inputStream)
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
                variables[num] = Variable(v.name, !v.independent)
            end
        catch
            println("Please only write numbers")
            continue
        end
    end
    variables
end

function readVariablesFromJSON(path)
    map(JSON.parsefile(path)) do jsonVar
        Variable(jsonVar["name"], jsonVar["independent"])
    end
end

function askForVariableValues(variableSet::Set{Variable}, enforceAllSet=true, input=stdin)
    results = Dict()
    for variableName in variableSet
        print("$(variableName): ")
        value = readline(input)
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