using Test
using DaemonMode

@testset "Test argument parsing" begin
    @test DaemonMode.parse_arguments("arg1 \"arg2 is in quotes\" arg3") == ["arg1", "arg2 is in quotes", "arg3"]

    @test DaemonMode.parse_arguments("arg1 arg2  \"arg3 is in quotes\"") == ["arg1", "arg2", "arg3 is in quotes"]

    @test DaemonMode.parse_arguments("arg1 arg2  \"arg3 has escaped \\\"quotes\\\"") == ["arg1", "arg2", "arg3 has escaped \"quotes\""]
end
