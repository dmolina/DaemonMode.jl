module DaemonMode

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end

const first_time = [true]
const token_end = "DaemonMode::Exit"

function serve(port=PORT)
    server = Sockets.listen(Sockets.localhost, port)
    global first_time
    global token_end
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
            println(sock, token_end)
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
            m = Module()
            content = join(readlines(joinpath(dir, fname)), "\n")
            include_string(m, content)
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

        while !isempty(ARGS)
            pop!(ARGS)
        end

        redirect_stdout(old)
        redirect_stderr(old_error)

        if !isempty(error)
            println(sock, error)
        end

        println(sock, token_end)

        while !isempty(ARGS)
            pop!(ARGS)
        end
    end
end

function runfile(fname::AbstractString; args=String[], port=port, output=stdout)
    global token_end
    dir = dirname(fname)

    if isempty(dir)
        fcompletename = joinpath(dir, fname)
    else
        fcompletename = fname
    end

    try
        sock = Sockets.connect(port)
        println(sock, pwd())
        println(sock, fcompletename)
        println(sock, join(args, " "))
        line = readline(sock)

        while (line != token_end)
            println(output, line)
            line = readline(sock)
        end
    catch e
        println(stderr, "Error, cannot connected with server. It is running?")
    end
    return
end

function runargs(port=PORT)
    if isempty(ARGS)
        println(file=stderr, "Error: missing filename")
    end
    runfile(ARGS[1], args=ARGS[2:end], port=port)
end

export serve
export runfile
export runargs

end # module
