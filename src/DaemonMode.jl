module DaemonMode

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end

const first_time = [true]

function serve()
    server = Sockets.listen(Sockets.localhost, PORT)
    global first_time
    quit = false
    current = pwd()

    while !quit
        sock = accept(server)
        dir = readline(sock)
        fname = readline(sock)
        args_str = readline(sock)
        args = split(args_str, " ")

        for arg in args
            push!(ARGS, arg)
        end

        first_time .= true
        cd(current)

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
            cd(dir)
            include(joinpath(dir, fname))
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

        while !isempty(ARGS)
            pop!(ARGS)
        end


    end
end

function runfile(fname::AbstractString, args=String[])
    dir = dirname(fname)

    if isempty(dir)
        fcompletename = joinpath(dir, fname)
    else
        fcompletename = fname
    end

    try
        sock = Sockets.connect(PORT)
        println(sock, pwd())
        println(sock, fcompletename)
        println(sock, join(args, " "))
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
    if isempty(ARGS)
        println(file=stderr, "Error: missing filename")
    end
    runfile(ARGS[1], ARGS[2:end])
end

export serve
export runfile
export runargs

end # module
