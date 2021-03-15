# User Guide

This package has been developed taking in account the usage easily.

# Usage

- The server is the responsible of running all julia scripts.
 
  ```sh
  julia -e 'using DaemonMode; serve()'
```

- A client, that send to the server the file to run, and return the output
  obtained.
  
```@sh
  julia -e 'using DaemonMode; runargs()' program.jl <arguments>
```

  you can use an alias 
  ```sh
  alias juliaclient='julia -e "using DaemonMode; runargs()"'
```
  
then, instead of `julia program.jl` you can do `juliaclient program.jl`. The
output should be the same, but with a lot less time.

# Running specific code


Although the function `runargs()` is the simpler way to run the client, it is not
the only function.

```@docs
```

# Running several clients at the same time

In previous versions, the server run one task for each client. However, since
v0.1.5 DaemonMode is able to run each client in parallel. However, you can run the
server function with the parameter async=false to have the previous behaviour.

```sh
$  julia -e 'using DaemonMode; serve(async=false)'
```

With the optional parameter async=true to server, the server run each client in
a new task.

```sh
$  julia -e 'using DaemonMode; serve(async=true)'
```

That command will allow to run different clients parallel, but it will use only one CPU. 

If you want to use several threads, you can do:

```sh
$  julia -t auto -e 'using DaemonMode; serve(async=true)'
```

Auto allows DaemonMode to use all processors of the computer, but you can put 
*-t 1*, *-t 2*, ...

The async option have several advantages:

- You can run any new client without waiting the previous close.

- If one process ask for close the Daemon, it will wait until all clients have
  been finished.
  
- With several threads (indicated with *-t*), you can run several clients in
  different CPUs, without increasing the time for each client. If there is only
  one process, the processing time will be divided between the different
  clients.
 
The main drawback is that the @show and logs in console can be send to the last task.

# Typical errors

```sh
Error, cannot connect with server. Is it running?
```

It could not be connected with the server, you should check it is running, and
that the port used in both is the same one.

```sh
ERROR: could not open file '<file>'
```

the file cannot be found by the server. Remember that the file is going to be
searched using as current directory the directory in which the julia client is
run.

# Changing the port

By default the DaemonMode work in the port 3000, but in many contexts that port
can be unavailable, or been busy for another application.

it is simple to change the port, but it must be done both in the server and the client.

- In the server:

```julia
   using DaemonMode: serve

   serve(port=9000)
```

- In the client:

```julia
   using DaemonMode: runargs

   runargs(port=9000)
```

- or using the alias:

```sh
  alias juliaclient='julia -e "using DaemonMode; runargs(port=9000)"'
```

That port keyword can be add to any other parameter.

# Different contexts

In order to avoid conflict of different versions of the same library, sometimes
it is needed to run programs using different contexts  or environments.

This can be achieve with DaemonMode run different servers, each one using a
different port.

```julia
# server1.jl
using Pkg
Pkg.activate("<env_dir1>")
using DaemonMode: serve
serve(3001)
```

```julia
# server2.jl
using Pkg
Pkg.activate("<env_dir2>")
using DaemonMode: serve
serve(3002)
```

First, we run the two servers:

```sh
> julia server1.jl &
> julia server2.jl &
```

Then, to run *file1.jl* in the first context and run *file2.jl* in second
environment.

```sh
julia -e 'using DaemonMode; runargs(3001)' file1.jl
```

```sh
julia -e 'using DaemonMode; runargs(3002)' file1.jl
```

# Shared code and Conflict of names

By default each file/expression is run in a new Module to avoid any conflict of
names. This implies that each run is completely independently. 

It is possible to run the different files/expressions in the same Module, using
the parameter shared to *true* in the function `serve()`. This implies that the
variables are shared between the different clients. It could be useful to avoid
repeating evaluations, but it could produce conflict of names.

```sh
julia -e 'using DaemonMode; runargs(3001)' file1.jl
```
# Debugging a script

Sometimes the script is not lack of errors, in this case, it is only show the
first line of error.

By example:

```julia
function fun2(a)
    println(a+b)
end

function fun1()
    fun2(4)
end

fun1()
```

and the server:

```sh
julia --project -e 'using DaemonMode; serve(3000)'
```

The output usually should be:

```sh
# julia --project=. -e "using DaemonMode; runargs()" test/bad.jl 
LoadError: syntax: incomplete: premature end of input
in expression starting at string:1
```

This is usually not wanted. 

In order to fix it, and to receive more informative messages, it is recommended
the parameter print_stack:

```sh
julia --project -e 'using DaemonMode; serve(3000, print_stack=true)'
```

When it is run the code now more informative messages:

```sh
# julia --project=. -e "using DaemonMode; runargs()" test/bad2.jl 
LoadError: UndefVarError: b not defined
Stacktrace:
 [1] fun2(::Int64) at ./string:2
 [2] fun1() at ./string:6
 [3] top-level scope at string:9
 [4] include_string(::Function, ::Module, ::String, ::String) at ./loading.jl:1088
 [5] include_string at ./loading.jl:1096 [inlined] (repeats 2 times)
 [6] #7 at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:140 [inlined]
 [7] (::DaemonMode.var"#3#5"{DaemonMode.var"#7#9"{String},Sockets.TCPSocket,Bool,Bool})() at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:97
 [8] redirect_stderr(::DaemonMode.var"#3#5"{DaemonMode.var"#7#9"{String},Sockets.TCPSocket,Bool,Bool}, ::Sockets.TCPSocket) at ./stream.jl:1150
 [9] #2 at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:88 [inlined]
 [10] redirect_stdout(::DaemonMode.var"#2#4"{DaemonMode.var"#7#9"{String},Sockets.TCPSocket,Bool,Bool}, ::Sockets.TCPSocket) at ./stream.jl:1150
 [11] serverRun at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:87 [inlined]
 [12] #6 at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:139 [inlined]
 [13] cd(::DaemonMode.var"#6#8"{Sockets.TCPSocket,Bool,Bool,String}, ::String) at ./file.jl:104
 [14] serverRunFile(::Sockets.TCPSocket, ::Bool, ::Bool) at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:137
 [15] serve(::Int64, ::Missing; print_stack::Bool) at /mnt/home/daniel/working/DaemonMode/src/DaemonMode.jl:40
 [16] top-level scope at none:1
 [17] eval(::Module, ::Any) at ./boot.jl:331
 [18] exec_options(::Base.JLOptions) at ./client.jl:272
 [19] _start() at ./client.jl:506
in expression starting at string:9
```

Obviously, the majority of the complete stack mention the DaemonMode functions,
but at least the error can be identified more easily.

# Including a file

In first versions of the package, you cannot use the "include" function to
include the code of an external file (for a better organization of the code).
This has been solved, so now you can use include function as normal.

Example:

In file **include_test.jl**:

```julia
include("to_include.jl")

println(f_aux(2,3))
```

and in **to_include.jl**:

```julia
function f_aux(a,b)
    return a*b
end
```

```sh
# julia --project=. -e "using DaemonMode; runargs()" include_test.jl 
6
```

Remember that the current directory is the directory in which julia command is
run, so it is recommended to run in the same directory that the script with the include.

