using DaemonMode
using Test
using Sockets


function init_server(port)
    task = @async serve(port, async=false)
    sleep(1)
    return task
end

function end_server(task, port)
    sendExitCode(port)
    wait(task)
end



function test_evalfile(file; port)
    task = init_server(port)
    buffer = IOBuffer()
    runfile(file, output=buffer, port=port)
    output = String(take!(buffer))
    end_server(task, port)
    return output
end

function test_evalcode_file(file; port)
    task = init_server(port)
    buffer = IOBuffer()
    code = runfile(file, output=buffer, port=port)
    output = String(take!(buffer))
    end_server(task, port)
    return output, code
end


function test_evalfiles(files; port)
    task = init_server(port)
    buffer = IOBuffer()
    outputs = String[]

    for file in files
        runfile(file, output=buffer, port=port)
        push!(outputs, String(take!(buffer)))
    end

    end_server(task, port)
    return outputs
end

@testset "Start Server" begin
    port = 3001
    @test_throws Base.IOError connect(port)
    task = @async serve(port, async=false)
    sleep(1)
    sendExitCode(port)
    wait(task)
end

@testset "runFile" begin
    files = ["hello.jl", "hello2.jl", "print.jl"]
    expected = ["Hello, World!\n", "Hello, World\n\nBye, World!\n", "Hello, World"]
    outputs = test_evalfiles(files, port=3002)

    for (expected, output) in zip(expected, outputs)
        @test output == expected
    end
end

@testset "runExpr" begin
    port = 3003
    task = @async serve(port, async=false)
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
    files = ["conflict1.jl", "conflict2.jl"]
    outputs = test_evalfiles(files, port=3004)
    expected = ["f(1) = 2\n", "f + 2 = 3\n"]

    for (expect, output) in zip(expected, outputs)
        @test expect == output
    end
end

@testset "runFileError" begin
    port = 3004
    task = init_server(port)
    files = ["bad.jl", "hello.jl"]
    expected = [1, 0]

    buffer = IOBuffer()

    for (file, return_code) in zip(files, expected)
        code = runfile(file, output=buffer, port=port)
        @test code == return_code
    end

    end_server(task, port)
end



@testset "testInclude" begin
    output = test_evalfile("include_test.jl", port=3006)
    @test output == "6\n"
end

@testset "testLogs" begin
    output = test_evalfile("test_log1.jl", port=3007)
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


@testset "testArgs" begin
    output = test_evalfile("args.jl", port=3008)
    lines = split(output, "\n")
    @test lines[1] == "String[]"
end


@testset "exit" begin
    output, code = test_evalcode_file("test_exit_0.jl", port=3009)
    @test output == "Before\n"
    @test code == 0
    output, code = test_evalcode_file("test_exit_1.jl", port=3009)
    @test output == "Before\n"
    @test code == 1
end

@testset "testEval" begin
    output = test_evalfile("eval.jl", port=3010)
    @test output == "3\n"
end

@testset "testCodeloc" begin
    output = test_evalfile("fileandline.jl", port=3011)
    l = split(output)
    @test endswith(l[1], joinpath("test", "fileandline.jl"))
    @test l[2] == "7"
end
