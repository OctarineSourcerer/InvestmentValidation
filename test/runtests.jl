using InvestmentValidation
using Test

# Brittle test to check variable creation goes okay
@testset "Variables Creation" begin
    testInput = """One
    Two
    Three
    Four

    1 3
    2
    3

    """

    @test InvestmentValidation.askForVariables(IOBuffer(testInput)) == [
        Variable("One", true),
        Variable("Two", true),
        Variable("Three", false),
        Variable("Four", false)
    ]
end