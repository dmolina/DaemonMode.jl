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
        fname = readline(sock)

        if (fname == "exit()")
            println(sock, "")
            sleep(1)
            quit = true
            continue
        end

        (_, old) = redirect_stdout()
        redirect_stdout(sock)
        (_, old_error) = redirect_stderr()
        redirect_stderr(sock)
        error = ""

        try
            include(fname)
        catch e
            if isa(e, LoadError)
                if :msg in propertynames(e.error)
                    error_msg = e.error.msg
                else
                    error_msg = "$e.error"
                end

                error = "ERROR in line $(e.line): '$(error_msg)'"
            else
                error = "ERROR: could not open file '$fname'"
            end
        end

        redirect_stdout(old)
        redirect_stderr(old_error)

        if !isempty(error)
            println(sock, error)
        end

        println(sock, "")
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
