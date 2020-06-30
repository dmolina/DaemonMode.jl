module DaemonMode

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end 

function serve()
    server = Sockets.listen(Sockets.localhost, PORT)
    (out, old) = redirect_stdout()

    while true
        sock = accept(server)
        fname = readline(sock)
        include(fname)
        data = readline(out)
        println(sock, data)
        println(sock, "")

        # for line in readlines(out)
        #     println(line)
        #     println(sock, line)
        # end
    end
end

function runfile(fname::AbstractString)
    dir = dirname(fname)

    if isempty(dir)
        fcompletename = joinpath(dir, fname)
    else
        fcompletename = fname
    end

    try
        sock = Sockets.connect(PORT)
        println(sock, fcompletename)
        line = readline(sock)

        while (!isempty(line))
            println(line)
            line = readline(sock)
        end
    catch e
        println(stderr, "Error, cannot connected with server. It is running?")
    end
    return
end

function runargs()
    runfile(only(ARGS))
end

export serve
export runfile
export runargs

end # module
