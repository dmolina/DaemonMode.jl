using Base.Threads: sleep

@show ARGS

if isempty(ARGS)
    time = 5
else
    time = parse(Int, ARGS[1])
end

for t in 1:time
    println("Long: $t -> $time")
    println(stderr, "LongError: $t -> $time")
    sleep(rand([0.5, 0.8, 1]))
end
println("Finished after waiting $(time) seconds")
