using DaemonMode
using Test
using Sockets

@testset "Start Server" begin
    (out, old) = redirect_stderr()
    @test_throws Base.IOError connect(3000)
    redirect_stderr(old)
    task = Threads.@spawn serve()
    runfile("exit()")
    sleep(1)
end

@testset "Hello" begin
    task = Threads.@spawn serve()
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
    runfile("exit()")
    sleep(1)
end
