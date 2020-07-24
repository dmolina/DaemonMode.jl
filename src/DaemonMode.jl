module DaemonMode

export serve, runfile, runargs, runexpr, sendExitCode

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end

const first_time = Ref(true)
const token_runfile = "DaemonMode::runfile"
const token_runexpr = "DaemonMode::runexpr"
const token_exit = "DaemonMode::exit"
const token_end = "DaemonMode::end"

function serve(port=PORT)
    server = Sockets.listen(Sockets.localhost, port)
    quit = false
    current = pwd()

    while !quit
        sock = accept(server)
        mode = readline(sock)
        
        redirect_stdout(sock) do
            redirect_stderr(sock) do
                
                if mode == token_runfile
                    serverRunFile(sock)
                elseif mode == token_runexpr
                    serverRunExpr(sock)
                elseif mode == token_exit
                    println(sock, token_end)
                    sleep(1)
                    quit = true
                else
                    println(sock, "Error, unrecognised mode, expected (\"runFile()\", \"runExpr()\" or \"exit()\", but received \"$mode\"")
                    quit = true
                end

            end
        end

    end
    close(server)
end

function serverRunFile(sock)
    dir = readline(sock)
    fname = readline(sock)
    args_str = readline(sock)
    args = split(args_str, " ")

    append!(ARGS, args)

    first_time[] = true
    error = ""

    try
        cd(dir) do 
            m = Module()
            content = join(readlines(joinpath(dir, fname)), "\n")
            include_string(m, content)
        end
    catch e
        if isa(e, LoadError)
            if :msg in propertynames(e.error)
                error_msg = e.error.msg
            else
                error_msg = "$(e.error)"
            end
            error = "ERROR in line $(e.line): '$(error_msg)'"
        else
            error = "ERROR: could not open file '$fname'"
        end
    end

    !isempty(error) && println(sock, error)
    println(sock, token_end)
    empty!(ARGS)
end

function serverRunExpr(sock)
    dir = readline(sock)
    expr = readuntil(sock, token_end) # Read until token_end to handle multi-line expressions
    error = ""

    try
        cd(dir) do 
            evaledExpr = Meta.parse(expr)
            Main.eval(evaledExpr)
        end
    catch e
        if isa(e, LoadError)
            if :msg in propertynames(e.error)
                error_msg = e.error.msg
            else
                error_msg = "$(e.error)"
            end
            error = "ERROR in line $(e.line): '$(error_msg)'"
        else
            error = "ERROR: $e"
        end
    end

    !isempty(error) && println(sock, error)
    println(sock, token_end)
    empty!(ARGS)
end

function runexpr(expr::AbstractString ; output = stdout, port = PORT)
    try
        sock = Sockets.connect(port)
        println(sock, token_runexpr)
        println(sock, pwd())
        println(sock, expr)
        println(sock, token_end)

        line = readline(sock)
        while (line != token_end)
            println(output, line)
            line = readline(sock)
        end

    catch e
        println(stderr, "Error, cannot connect with server. Is it running?")
    end
end

function runfile(fname::AbstractString; args=String[], port = PORT, output=stdout)
    dir = dirname(fname)

    if isempty(dir)
        fcompletename = joinpath(dir, fname)
    else
        fcompletename = fname
    end
    try
        sock = Sockets.connect(port)
        println(sock, token_runfile)
        println(sock, pwd())
        println(sock, fcompletename)
        println(sock, join(args, " "))
        line = readline(sock)
        while (line != token_end)
            println(output, line)
            line = readline(sock)
        end
    catch e
        println(stderr, "Error, cannot connect with server. Is it running?")
    end
    return
end

function sendExitCode(port = PORT)
    sock = Sockets.connect(port)
    println(sock, token_exit)
end

function runargs(port=PORT)
    if isempty(ARGS)
        println(file=stderr, "Error: missing filename")
    end
    runfile(ARGS[1], args=ARGS[2:end], port=port)
end


end # module
