using DaemonMode
using Test
using Sockets

@testset "Start Server" begin
    @test_throws Base.IOError connect(3000)
    task = @async serve()
    sleep(1)
    sendExitCode()
    wait(task)
end

@testset "runFile" begin
    task = @async serve()
    sleep(1)
    buffer = IOBuffer()
    files = ["hello.jl", "hello2.jl"]
    outputs = ["Hello, World!\n", "Hello, World\n\nBye, World!\n"]

    for (file, out) in zip(files, outputs)
        @test isfile(file)
        runfile(file, output=buffer)
        output = String(take!(buffer))
        @test output == out
    end

    sendExitCode()
    wait(task)
end

@testset "runExpr" begin
    task = @async serve()
    sleep(1)

    buffer = IOBuffer()
    expr = "x = 3 ; for i = 1:x ; println(i) ; end"
    runexpr(expr, output=buffer)
    output = String(take!(buffer))
    @test output == "1\n2\n3\n"


    buffer = IOBuffer()
    expr = "begin
        x = 2
        for i = 1:2
            println(i)
        end
    end"
    runexpr(expr, output=buffer)
    output = String(take!(buffer))
    @test output == "1\n2\n"

    sendExitCode()
    wait(task)
end