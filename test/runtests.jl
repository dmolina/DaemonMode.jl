using DaemonMode
using Test
using Sockets

@testset "Start Server" begin
    port = 3001
    @test_throws Base.IOError connect(port)
    task = @async serve(port)
    sleep(1)
    sendExitCode(port)
    wait(task)
end

@testset "runFile" begin
    port = 3002
    task = @async serve(port)
    sleep(1)
    buffer = IOBuffer()
    files = ["hello.jl", "hello2.jl", "print.jl"]
    outputs = ["Hello, World!\n", "Hello, World\n\nBye, World!\n", "Hello, World"]

    for (file, out) in zip(files, outputs)
        @test isfile(file)
        runfile(file, output=buffer, port=port)
        output = String(take!(buffer))
        @test output == out
    end

    sendExitCode(port)
    wait(task)
end

@testset "runExpr" begin
    port = 3003
    task = @async serve(port)
    sleep(1)

    buffer = IOBuffer()
    expr = "x = 3 ; for i = 1:x ; println(i) ; end"
    runexpr(expr, output=buffer, port=port)
    output = String(take!(buffer))
    @test output == "1\n2\n3\n"


    buffer = IOBuffer()
    expr = "begin
        x = 2
        for i = 1:2
            println(i)
        end
    end"
    runexpr(expr, output=buffer, port=port)
    output = String(take!(buffer))
    @test output == "1\n2\n"

    expr = """
    begin
        x = 2
        for i = 1:2
            println(i)
        end
    end

    """
    runexpr(expr, output=buffer, port=port)
    output = String(take!(buffer))
    @test output == "1\n2\n"

    sendExitCode(port)
    wait(task)
end

@testset "runConflict" begin
    port = 3004
    task = @async serve(port)
    sleep(1)
    buffer = IOBuffer()
    files = ["conflict1.jl", "conflict2.jl"]
    outputs = ["f(1) = 2\n", "f + 2 = 3\n"]

    for (file, out) in zip(files, outputs)
        @test isfile(file)
        runfile(file, output=buffer, port=port)
        output = String(take!(buffer))
        @test output == out
    end

    sendExitCode(port)
    wait(task)
end

@testset "testInclude" begin
    port = 3005
    task = @async serve(port)
    sleep(1)
    buffer = IOBuffer()
    files = ["conflict1.jl", "conflict2.jl"]
    runfile("include_test.jl", output=buffer, port=port)
    output = String(take!(buffer))
    @test output == "6\n"
end
