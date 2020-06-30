using DaemonMode
using Test
using Sockets

@testset "DaemonMode.jl" begin
    task = @async serve()
    sleep(1)
    runfile("hello.jl")
end
