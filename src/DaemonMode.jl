module DaemonMode

export serve, runfile, runargs, runexpr, sendExitCode

using Logging, LoggingExtras

using Crayons
using Crayons.Box

using Sockets

const PORT = 3000

function add_packages(fname::AbstractString)
end

const first_time = Ref(true)
const token_runfile = "DaemonMode::runfile"
const token_runexpr = "DaemonMode::runexpr"
const token_exit = "DaemonMode::exit"
const token_client_end = "DaemonMode::client_end"
const token_server_async_end = "DaemonMode::async_end"
const token_server_sync_end = "DaemonMode::sync_end"
const token_ok_end = "DaemonMode::end_ok"
const token_error_end = "DaemonMode::end_er"
const token_end = "DaemonMode::end"


"""
    serve_sync(port=3000, shared=false, print_stack=true, async=false)

Run the daemon, running all files and expressions sended by the client function.

# Optionals

- port: port to listen (default=3000).
- shared: Share the environment between calls. If it is false (default) each run
  has its own environment, so the variables/functions are not shared.
- print_stack: Print the complete stack when there is an error. By default it is true.
- async: Run the clients in different clients, **Experimental**.
"""
function serve(port=PORT, shared=missing; print_stack=true, async=false)
    if (async)
        return serve_async(port, shared, print_stack=print_stack)
    else
        return serve_sync(port, shared; print_stack=print_stack)
    end

end

function serve_async(port=PORT, shared=missing; print_stack=true, nicely=true)
    server = Sockets.listen(Sockets.localhost, port)
    current = pwd()
    continue_server = Threads.Atomic{Bool}(true)
    tasks = Task[]

    while continue_server[] && isopen(server)
        sock = accept(server)
        task = @async begin
            local mode
            mode = readline(sock)

            if mode == token_runfile
                serverRunFile(sock, coalesce(shared, false), print_stack)
            elseif mode == token_runexpr
                serverRunExpr(sock, coalesce(shared, true), print_stack)
            elseif mode == token_client_end
                println(sock, token_server_async_end)
                continue_server[] = false
            else
                println(sock, "Error, unrecognised mode, expected (\"runFile()\", \"runExpr()\" or \"exit()\", but received \"$mode\"")
                continue_server[] = false
            end
        end

        push!(tasks, task)
    end

    if nicely
        # wait all pending tasks
        for task in tasks
            try
                wait(task)
            catch e
            end
        end
    end

    close(server)
end

function serve_sync(port=PORT, shared=missing; print_stack=true)
    server = Sockets.listen(Sockets.localhost, port)
    current = pwd()
    continue_server = true

    while continue_server
        sock = accept(server)
        mode = readline(sock)

        if mode == token_runfile
            serverRunFile(sock, coalesce(shared, false), print_stack)
        elseif mode == token_runexpr
            serverRunExpr(sock, coalesce(shared, true), print_stack)
        elseif mode == token_client_end
            println(sock, token_server_sync_end)
            continue_server = false
        else
            println(sock, "Error, unrecognised mode, expected (\"runFile()\", \"runExpr()\" or \"exit()\", but received \"$mode\"")
            continue_server = false
        end
    end

    close(server)
end



function myshowerror(sock::IO, e)
    io = IOBuffer()
    showerror(io, e)
    msg = String(take!(io))
    line = first(split(msg, '\n'))
    posi = findfirst(':', line)
    print(sock, RED_FG, BOLD, "ERROR: ")
    print(sock, Crayon(foreground=:white, bold=false), line[1:posi])
    print(sock, Crayon(foreground=:red, bold=false), line[posi+1:end])
    print(sock, Crayon(reset=true))
end

function serverReplyError(sock, e)
    try
        myshowerror(sock, e)
        println(sock)
        println(sock, token_error_end)
    catch e
        if (e isa Base.IOError) && abs(e.code) == abs(Libc.EPIPE)
            # client disconnected early, ignore
        else
            rethrow()
        end
    end
end

function send_backtrace(sock, bt, fname)
    stacks = map(first, Base.process_backtrace(bt))
    fullname = ""

    if !isempty(stacks)
        println(sock)
        println(sock, "Stacktrace:")
    end

    if !isempty(fname)
        fullname = joinpath(pwd(), fname)
    end

    for (i, stack) in enumerate(stacks)
        file = String(stack.file)

        if occursin("string", file) && !isempty(fullname)
            file = fullname
        end

        if occursin("loading.jl", file)
            return
        end

        print(sock, " [$i] ")

        print(sock, BOLD, stack.func)
        print(sock, Crayon(reset=true), " at ")
        print(sock, BOLD, file, ":", stack.line)
        println(sock, Crayon(reset=true))
    end
end

function serverReplyError(sock, e, bt, fname)
    try
        myshowerror(sock, e)
        send_backtrace(sock, bt, fname)
        println(sock)
        println(sock, token_error_end)
    catch e
        if (e isa Base.IOError) && abs(e.code) == abs(Libc.EPIPE)
            # client disconnected early, ignore
        else
            rethrow()
        end
    end
end

function create_mylog(fname)
    function mylog(io, args)
        reset = Crayon(reset=true)
        color = reset
        type = string(args.level)

        if args.level == Logging.Warn
            color = Crayon(foreground=:yellow, bold=true)
            type = "Warning"
        elseif args.level == Logging.Error
            color = Crayon(foreground=:red, bold=true)
        elseif args.level == Logging.Info
            color = Crayon(foreground=:cyan, bold=true)
        end

        print(io, color, "┌ ", type, ": ", reset);
        lines = split(args.message, "\n")
        println(io, lines[1])

        for line in lines[2:end]
            println(io, color, "│ ", reset, line)
        end

        module_str = string(args._module)
        module_str = replace(module_str, ".anonymous" => "")
        file = args.file

        if file == "string"
            file = joinpath(pwd(), fname)
        end

        println(io, color, "└ ", Crayon(foreground=:dark_gray), "@ ", module_str, " ", file, ": ", args.line)
    end
end

function serverRun(run, sock, shared, print_stack, fname)
 #   redirect_stdout(sock) do
        redirect_stderr(sock) do

            try
                if shared
                    run(Main)
                else
                    m = Module()
                    Logging.global_logger(MinLevelLogger(FormatLogger(create_mylog(fname), sock), Logging.Info))
                    add_include = Meta.parse("include(arg)=Base.include(@__MODULE__,arg)")
                    Base.eval(m, add_include)
                    add_redirect = Meta.parse("const stdout=IOBuffer(); println(io, x...) = Base.println(io,x); println(x)=Base.println(stdout, x); println(io, x...)=Base.println(io, x); print(x)=Base.print(stdout, x); stdout")
                    out = Base.eval(m, add_redirect)
                    task = @async begin
                        while isopen(sock)
                            text = String(take!(out))
                            print(sock, text)
                            sleep(0.5)
                        end
                    end
                    run(m)
                    # If there is missing message I write it
                    text = String(take!(out))
                    print(sock, text)
                end
                println(sock, token_ok_end)

            catch e
                if print_stack
                    serverReplyError(sock, e, catch_backtrace(), fname)
                else
                    serverReplyError(sock, e)
                end
            end

  #      end
    end

end

"""
serverRunFile(sock, shared)

Run the source code of the filename push through the socket.

# Parameters

- sock: socket in which is going to receive the dir, the filename, and args to run.
- shared: Share the environment between calls. If it is false (default) each run
has its own environment, so the variables/functions are not shared.
""" 
function serverRunFile(sock, shared, print_stack)
    fname = ""

    try
        dir = readline(sock)
        fname = readline(sock)
        args_str = readline(sock)
        args = split(args_str, " ")

        if !isempty(args) && !isempty(args[1])
            append!(ARGS, args)
        end

        first_time[] = true

        cd(dir) do
            content = read(fname, String)
            serverRun(sock, shared, print_stack, fname) do mod
                include_string(mod, content)
            end
        end
    catch e
        serverReplyError(sock, e)
    end

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
function serverRunExpr(sock, shared, print_stack)

    try
        dir = readline(sock)
        expr = readuntil(sock, token_end) # Read until token_end to handle multi-line expressions
        parsedExpr = Meta.parse(strip(expr))

        cd(dir) do
            serverRun(sock, shared, print_stack, "") do mod
                Base.eval(mod, parsedExpr)
            end
        end
    catch e
        serverReplyError(sock, e)
    end

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
        while (line != token_ok_end && line != token_error_end)
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
    result = 0
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
        token_size = length(token_ok_end)

        while (length(line) < token_size || !occursin(token_end, line))
            println(output, line)
            line = readline(sock)
        end

        if occursin(token_error_end, line)
            result = 1
        end

        if length(line) > token_size
            end_line = replace(line, token_ok_end => "")
            end_line = replace(end_line, token_error_end => "")
            print(output, end_line)
        end
    catch e
        println(stderr, "Error, cannot connect with server. Is it running?")
        # println(stderr, e)
        exit(1)
    end
    return result
end

"""
    sendExitCode(port)

send the exit code, it closes the server.

# Optionals

- port: port to connect (default=3000).
"""
function sendExitCode(port=PORT)
    sock = Sockets.connect(port)
    println(sock, token_client_end)
    line = readline(sock)
    error = true

    if line == token_server_sync_end
        error = false
    elseif line == token_server_async_end
        error = false

        # For async it is need to create a new connection
        try
            sock = Sockets.connect(port)
        catch e
        end
    end

    return error
end

"""
    runargs(port=PORT)

Ask the server to run all files in ARGS.

# Optionals

- port: Port of the server to ask (default=3000).
"""
function runargs(port=PORT)
    if isempty(ARGS)
        println(stderr, "Error: missing filename")
        exit(1)
    elseif !isfile(ARGS[1])
        println(stderr, "Error: file '$(ARGS[1])' doest not exist")
        exit(1)
    end

    result = runfile(ARGS[1], args=ARGS[2:end], port=port)
    exit(result)
end


end # module
