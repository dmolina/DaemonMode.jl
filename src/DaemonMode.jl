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

"""
    serve(port=3000, shared=false)

Run the daemon, running all files and expressions sended by the client function.

# Optionals

- port: port to listen (default=3000).
- shared: Share the environment between calls. If it is false (default) each run
  has its own environment, so the variables/functions are not shared.
"""
function serve(port=PORT, shared=false)
    server = Sockets.listen(Sockets.localhost, port)
    quit = false
    current = pwd()

    while !quit
        sock = accept(server)
        mode = readline(sock)

        redirect_stdout(sock) do
            redirect_stderr(sock) do

                if mode == token_runfile
                    serverRunFile(sock, shared)
                elseif mode == token_runexpr
                    serverRunExpr(sock, true)
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
"""
serverRunFile(sock, shared)

Run the source code of the filename push through the socket.

# Parameters

- sock: socket in which is going to receive the dir, the filename, and args to run.
- shared: Share the environment between calls. If it is false (default) each run
has its own environment, so the variables/functions are not shared.
""" 
function serverRunFile(sock, shared)
    dir = readline(sock)
    fname = readline(sock)
    args_str = readline(sock)
    args = split(args_str, " ")

    append!(ARGS, args)

    first_time[] = true
    error = ""

    try
        cd(dir) do
            content = join(readlines(fname), "\n")

            if (!shared)
                m = Module()
                include_string(m, content)
            else
                include(fname)
            end
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

"""
serverRunExpr(sock, shared)

Run the source code of the filename push through the socket.

# Parameters

- sock: socket in which is going to receive the code to run.
- shared: Share the environment between calls. If it is false (default) each run
has its own environment, so the variables/functions are not shared.
"""
function serverRunExpr(sock, shared)
    dir = readline(sock)
    expr = readuntil(sock, token_end) # Read until token_end to handle multi-line expressions
    error = ""

    try
        cd(dir) do
            if shared
                evaledExpr = Meta.parse(expr)
                Main.eval(evaledExpr)
            else
                evaledExpr = Meta.parse(expr)
                m = Model()
                m.eval(evaledExpr)
            end
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

"""
    runexpr(expr::AbstractString)

Ask the server to run julia code in a string pass as parameters.

# Parameters

- expr: Julia code to run in the server.

# Optionals

- port: Port (default=3000).
- output: stream in which it is shown the output of the run.
"""
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

"""
    runfile(fname::AbstractString)

Ask the server to run a specific filename.

# Parameters

- fname: Filename to run.

# Optionals

- args: List of arguments (array of String, default=[]).
- port: Port (default=3000)
- output: stream in which it is shown the output of the run.
"""
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

"""
    sendExitCode(port)

send the exit code, it closes the server.

# Optionals

- port: port to connect (default=3000).
"""
function sendExitCode(port=PORT)
    sock = Sockets.connect(port)
    println(sock, token_exit)
end

"""
    runargs(port=PORT)

Ask the server to run all files in ARGS.

# Optionals

- port: Port of the server to ask (default=3000).
"""
function runargs(port=PORT)
    if isempty(ARGS)
        println(file=stderr, "Error: missing filename")
    end
    runfile(ARGS[1], args=ARGS[2:end], port=port)
end


end # module
