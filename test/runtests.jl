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
    expr = "x = 3 ; for i = 1:x ; println(i) ; end\n"
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

    expr = "begin 
        x = 2
        for i = 1:2
            println(i)
        end
    end
    
    "

    runexpr(expr, output=buffer, port=port)
    output = String(take!(buffer))
    @test output == "1\n2\n"
    @test istaskdone(task) == false

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

@testset "runFileError" begin
    port = 3002
    task = @async serve(port)
    sleep(1)
    buffer = IOBuffer()
    files = ["bad.jl", "hello.jl"]
    outputs = [1, 0]

    for (file, out) in zip(files, outputs)
        @test isfile(file)
        sal = runfile(file, output=buffer, port=port)
        @test sal == out
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

@testset "testLogs" begin
    port = 3006
    task = @async serve(port)
    sleep(1)
    buffer = IOBuffer()
    runfile("test_log1.jl", output=buffer, port=port)
    output = String(take!(buffer))
    lines = split(output, "\n")
    # Remove colors
    lines = replace.(lines, r"\e\[.*?m"=>"")
    @test occursin("Warning: warning 1", lines[1])
    @test occursin("another line", lines[2])
    @test occursin("last one", lines[3])
    @test occursin("test_log1.jl: 4", lines[4])
    @test occursin(r"Error: error 1", lines[5])
    @test occursin("test_log1.jl: 5", lines[6])
    @test occursin("Info: info 1", lines[7])
    @test occursin("test_log1.jl: 6", lines[8])
end
