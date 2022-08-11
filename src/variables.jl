using DataFrames, DataFramesMeta, OrderedCollections, JSON
import Base: ==, show
export Variable

mutable struct Variable
    name::String
    independent::Bool
end
# Here mostly for purposes of testing atm. I'd LIKE for the struct to be immutable, but we're literally changing variable content possibly over and over before confirming.
# So it's MUCH less fragile to just... not have to juggle indices and variables ALL the time.
function ==(a::Variable, b::Variable)
    a.name == b.name && a.independent == b.independent
end

# Values used to colour dependent and independent variables
const independentColour = :yellow
const dependentColour = :light_blue

function show(io::IO, x::AbstractVector{Variable})
    for (i, var) in enumerate(x)
        colour = if var.independent independentColour else dependentColour end
        printstyled(io, "$i: ", color=colour)
        println(io, var.name)
    end
end

function chooseIndices(array; inputStream = stdin)
    while true
        input = readline(inputStream)
        if input == ""
            return missing
        end
        elements = split(input, " ")
        try
            numbers = map(x -> parse(Int, x), elements)
            if !all(i -> i > 0 && i <= lastindex(array), numbers)
                error("User supplied number outside bounds of array")
            end
            return numbers
        catch
            println("Please only write numbers")
            continue
        end
    end 
end

"""
`chooseVariablesAndDo(doWithChosen, variables, preMessageFunction)`

Runs preMessageFunction before letting the user choose variables, then running the given function on them
"""
# messageFunction lets you do fancy printing without this function ever touching the formatting. But, do a version that lets in just the string?
function chooseVariablesAndDo(doWithChosen, preMessageFunction, variables::AbstractVector{Variable}; inputStream=stdin, justOnce=false)
    while true
        preMessageFunction()
        show(stdout, variables)
        numbers = chooseIndices(variables; inputStream=inputStream)
        if ismissing(numbers)
            break
        end
        for num in numbers
            doWithChosen(variables[num])
        end
        if justOnce return variables end
    end
    variables
end

"Ask the user for a set of variables that are present"
function askForVariables(inputStream=stdin)::Vector{Variable}
    variables = Vector{Variable}()
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
    function printF()
        print("Choose which variables to toggle between "); printstyled("dependent", color=dependentColour); print(" and "); printstyled("independent", color=independentColour); println(" (eg '1 3')")
    end 
    chooseVariablesAndDo(printF, variables, inputStream=inputStream) do var
        var.independent = !var.independent
    end
    variables
end

function readVariablesFromJSON(path)
    map(JSON.parsefile(path)) do jsonVar
        Variable(jsonVar["name"], jsonVar["independent"])
    end
end

function askForVariableValues(variables, enforceAllSet=true, input=stdin)
    results = Dict()
    for variableName in variables
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

"Given a set of variables, let the user assign these to questions"
function tagData(data, variables::Vector{Variable}; inputStream=stdin)
    colNames = names(data)
    colMeasures = Dict{String, Variable}()
    for colName in colNames
        column = data[:, colName]
        println("Column $(colName)")
        # show(column)
        function printF()
            println("Which variable does this measure? Empty line to skip.")
        end
        chooseVariablesAndDo(printF, variables, justOnce=true) do var
            push!(colMeasures, (colName => var))
        end
    end
    colMeasures
end