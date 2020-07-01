module DaemonMode

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end 

function serve()
    server = Sockets.listen(Sockets.localhost, PORT)
    quit = false

    while !quit
        sock = accept(server)
        (out, old) = redirect_stdout()
        (err, olderror) = redirect_stderr()
        fname = readline(sock)

        if (fname == "exit()")
            println(sock, "")
            sleep(1)
            quit = true
            continue
        end

        try
            include(fname)
            data = readline(out)
            redirect_stdout(old)
            redirect_stderr(olderror)
            println(sock, data)
        catch e
            redirect_stdout(old)
            redirect_stderr(olderror)
            println("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE")
            println(sock, err)
        end

        println(sock, "")

        # for line in readlines(out)
        #     println(line)
        #     println(sock, line)
        # end
        # redirect_stderr(err)
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
